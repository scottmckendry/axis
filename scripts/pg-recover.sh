#!/usr/bin/env bash

# 🔄 PostgreSQL Cluster Recovery Helper
# Interactively recover PostgreSQL cluster to a point in time using CNPG

set -euo pipefail

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${1:-postgresql-cluster}"
CLUSTER_NAMESPACE="${2:-databases}"
CLUSTER_MANIFEST="${3:-kubernetes/platform/databases/postgresql/cluster.yaml}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🔄 PostgreSQL Cluster Recovery${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Pre-flight checks
echo -e "${YELLOW}🔍 Pre-flight checks...${NC}"
if ! kubectl get cluster "$CLUSTER_NAME" -n "$CLUSTER_NAMESPACE" >/dev/null 2>&1; then
	echo -e "${RED}❌ Cluster $CLUSTER_NAME not found in namespace $CLUSTER_NAMESPACE${NC}"
	exit 1
fi

if [[ ! -f "$CLUSTER_MANIFEST" ]]; then
	echo -e "${RED}❌ Cluster manifest not found at $CLUSTER_MANIFEST${NC}"
	exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
	echo -e "${RED}❌ fzf is required but not installed${NC}"
	exit 1
fi

echo -e "${GREEN}✅ All checks passed${NC}\n"

# Show current status
echo -e "${BOLD}📊 Current cluster status:${NC}"
kubectl get cluster "$CLUSTER_NAME" -n "$CLUSTER_NAMESPACE"
echo ""

# Warning message
echo -e "${YELLOW}⚠️  WARNING: This will DELETE the PostgreSQL cluster and restore to a previous point in time.${NC}"
echo ""
echo "This operation will:"
echo "  1. Delete the existing cluster (causing downtime)"
echo "  2. Update the cluster manifest with the selected restore point"
echo "  3. Commit the changes to git"
echo "  4. Apply the updated manifest to initiate recovery"
echo ""

# Generate recovery point options with timestamps
cat >/tmp/recovery-options.txt <<EOF
latest|Latest available (most recent WAL)|latest
1h|1 hour ago|$(date -u -d "1 hour ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
2h|2 hours ago|$(date -u -d "2 hours ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
6h|6 hours ago|$(date -u -d "6 hours ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
12h|12 hours ago|$(date -u -d "12 hours ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
1d|Yesterday|$(date -u -d "1 day ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
2d|2 days ago|$(date -u -d "2 days ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
7d|7 days ago|$(date -u -d "7 days ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
14d|14 days ago|$(date -u -d "14 days ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
30d|30 days ago (retention limit)|$(date -u -d "30 days ago" +"%Y-%m-%d %H:%M:%S.00000+00:00")
custom|Custom timestamp (you will be prompted)|custom
EOF

# Use FZF to select recovery point
SELECTION=$(cat /tmp/recovery-options.txt |
	awk -F'|' '{printf "%-8s %-35s %s\n", $1, $2, $3}' |
	fzf --height=40% \
		--border=rounded \
		--prompt="Select restore point: " \
		--header="Use arrow keys to navigate, Enter to select, Esc to cancel" \
		--preview='echo "Recovery Point Details:"; echo ""; echo {}' \
		--preview-window=up:3:wrap \
		--color=header:italic:underline)

if [[ -z "$SELECTION" ]]; then
	echo -e "${RED}❌ No selection made. Aborting.${NC}"
	rm -f /tmp/recovery-options.txt
	exit 1
fi

# Parse selection
MODE=$(echo "$SELECTION" | awk '{print $1}')
TIMESTAMP=$(echo "$SELECTION" | awk '{print $NF}')

# Handle custom timestamp input
if [[ "$MODE" == "custom" ]]; then
	echo ""
	echo -e "${BOLD}Enter custom timestamp (format: YYYY-MM-DD HH:MM:SS.00000+00:00):${NC}"
	read -r CUSTOM_TIME
	if [[ -z "$CUSTOM_TIME" ]]; then
		echo -e "${RED}❌ No timestamp provided. Aborting.${NC}"
		rm -f /tmp/recovery-options.txt
		exit 1
	fi
	TIMESTAMP="$CUSTOM_TIME"
	MODE="pitr"
elif [[ "$MODE" == "latest" ]]; then
	MODE="latest"
else
	MODE="pitr"
fi

# Cleanup temp file
rm -f /tmp/recovery-options.txt

# Show recovery details
echo ""
echo -e "${BOLD}🎯 Recovery configuration:${NC}"
echo -e "  Mode: ${GREEN}$MODE${NC}"
if [[ "$MODE" == "pitr" ]]; then
	echo -e "  Target time: ${GREEN}$TIMESTAMP${NC}"
else
	echo -e "  Target: ${GREEN}Latest available WAL${NC}"
fi
echo ""

# Final confirmation
echo -e "${YELLOW}⚠️  This will DELETE the cluster and initiate recovery!${NC}"
echo -e "Press ${BOLD}Ctrl+C${NC} to cancel, or ${BOLD}Enter${NC} to continue..."
read -r

# Create backup timestamp
BACKUP_TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Backup manifest
echo -e "${BLUE}💾 Backing up current manifest...${NC}"
cp "$CLUSTER_MANIFEST" "${CLUSTER_MANIFEST}.backup-${BACKUP_TIMESTAMP}"
echo -e "${GREEN}✅ Backup saved to ${CLUSTER_MANIFEST}.backup-${BACKUP_TIMESTAMP}${NC}"

# Delete cluster
echo -e "${BLUE}🗑️  Deleting cluster $CLUSTER_NAME...${NC}"
kubectl delete cluster "$CLUSTER_NAME" -n "$CLUSTER_NAMESPACE" --wait=true
echo -e "${GREEN}✅ Cluster deleted${NC}"

# Update manifest with recovery configuration
echo -e "${BLUE}✏️  Updating cluster manifest...${NC}"

# Update recovery source
yq eval '.spec.bootstrap.recovery.source = "postgresql-backup"' -i "$CLUSTER_MANIFEST"

if [[ "$MODE" == "latest" ]]; then
	# Remove recoveryTarget for latest recovery
	yq eval 'del(.spec.bootstrap.recovery.recoveryTarget)' -i "$CLUSTER_MANIFEST"
else
	# Set PITR target
	yq eval ".spec.bootstrap.recovery.recoveryTarget.targetTime = \"$TIMESTAMP\"" -i "$CLUSTER_MANIFEST"
fi

# Remove barman plugin during recovery
yq eval 'del(.spec.plugins[] | select(.name == "barman-cloud.cloudnative-pg.io"))' -i "$CLUSTER_MANIFEST"

echo -e "${GREEN}✅ Manifest updated${NC}"

# Apply manifest
echo -e "${BLUE}🚀 Applying updated manifest to initiate recovery...${NC}"
kubectl apply -f "$CLUSTER_MANIFEST"
echo -e "${GREEN}✅ Recovery initiated!${NC}"

# Show next steps
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Recovery process started successfully!${NC}"
echo ""
echo -e "${BOLD}💡 Next steps:${NC}"
echo -e "  1. Monitor recovery: ${GREEN}just pg-monitor${NC}"
echo -e "  2. Restore manifest when complete: ${GREEN}just pg-restore-after-recovery${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
