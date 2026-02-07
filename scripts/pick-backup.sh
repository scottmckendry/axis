#!/usr/bin/env bash

# 🔍 Backup Selection Helper
# Interactively select a backup timestamp from restic snapshots
# requires: restic, jq, fzf, kubectl
# https://volsync.readthedocs.io/en/stable/usage/restic/index.html#restore-options

set -euo pipefail

# Colors and formatting
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🔍 Backup Selection Helper${NC}"

# Dynamically discover available ReplicationSources
echo -e "  ${GREEN}↳${NC} Discovering available backups from cluster..."
replication_sources=$(kubectl get replicationsource -A -o json 2>/dev/null |
	jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"')

if [[ -z "$replication_sources" ]]; then
	echo -e "${YELLOW}⚠️  No ReplicationSources found in the cluster.${NC}"
	echo -e "  ${GREEN}↳${NC} Falling back to manual input..."
	echo -ne "  ${GREEN}↳${NC} Enter namespace for restore: "
	read -r NAMESPACE
	echo -ne "  ${GREEN}↳${NC} Enter PVC name to restore: "
	read -r PVC_NAME
else
	# Use fzf to select from discovered sources
	selected_source=$(echo "$replication_sources" |
		fzf --height=40% \
			--border=rounded \
			--prompt="Select backup to restore: " \
			--header="Available ReplicationSources" \
			--preview='echo "Namespace/PVC: {}"' \
			--preview-window=up:3:wrap)

	if [[ -z "$selected_source" ]]; then
		echo -e "${YELLOW}❌ No selection made. Exiting.${NC}"
		exit 1
	fi

	# Parse namespace and PVC name from the ReplicationSource
	# Format is "namespace/name" where name is typically "namespace-pvcname"
	NAMESPACE=$(echo "$selected_source" | cut -d'/' -f1)
	SOURCE_NAME=$(echo "$selected_source" | cut -d'/' -f2)

	# Extract PVC name from source name (assuming format: namespace-pvcname)
	# Remove the namespace prefix if it exists
	if [[ "$SOURCE_NAME" == "${NAMESPACE}-"* ]]; then
		PVC_NAME="${SOURCE_NAME#${NAMESPACE}-}"
	else
		PVC_NAME="$SOURCE_NAME"
	fi

	echo -e "  ${GREEN}↳${NC} Selected: ${BOLD}$NAMESPACE/$PVC_NAME${NC}"
fi

SECRET_NAME="restic-$NAMESPACE-$PVC_NAME"
echo -e "  ${GREEN}↳${NC} Loading credentials from ${BOLD}$SECRET_NAME${NC}..."

SECRET_PROPS=(
	AWS_ACCESS_KEY_ID
	AWS_SECRET_ACCESS_KEY
	RESTIC_PASSWORD
	RESTIC_REPOSITORY
)

# Export required variables from kubernetes secret
for prop in "${SECRET_PROPS[@]}"; do
	if kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" &>/dev/null; then
		value=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.$prop}" | base64 --decode)
		export "$prop=$value"
	else
		echo -e "${YELLOW}Secret $SECRET_NAME not found in namespace $NAMESPACE${NC}" >&2
		exit 1
	fi
done

echo -e "  ${GREEN}↳${NC} Removing any stale locks..."
restic unlock 2>/dev/null || true
echo -e "  ${GREEN}↳${NC} Loading available backups..."

# Fetch and format backup list
backup_list=$(restic snapshots --json 2>/dev/null |
	jq -r '.[] | "\(.time) [\(.summary.total_bytes_processed/1024/1024 | floor)MB, \(.summary.total_files_processed) files] \(.paths[0])"')

if [[ -z "$backup_list" ]]; then
	echo -e "${YELLOW}No backups found for $NAMESPACE/$PVC_NAME${NC}"
	exit 1
fi

# Select from the backup list
selected=$(echo "$backup_list" |
	fzf --height 40% \
		--border=rounded \
		--tac \
		--prompt="Select backup snapshot: " \
		--header="Available backups for $NAMESPACE/$PVC_NAME")

# Extract just the timestamp part (everything before the first '[')
timestamp=$(echo "$selected" | cut -d'[' -f1 | xargs)

# Round up to the nearest minute for the "restoreAsOf" option
adjusted=$(date -d "$timestamp + 1 minute" +"%Y-%m-%dT%H:%M:00Z")

# Cleanup environment
for prop in "${SECRET_PROPS[@]}"; do
	unset "$prop"
done

if [[ -z "$adjusted" ]]; then
	echo -e "${YELLOW}No valid date selected. Exiting.${NC}"
	exit 1
fi

echo -e "  ${GREEN}↳${NC} Selected backup timestamp: ${BOLD}$adjusted${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Call the restore script directly
echo -e "  ${GREEN}↳${NC} Initiating restore..."
./scripts/restore.sh --name "$PVC_NAME" --namespace "$NAMESPACE" --restore-date "$adjusted" --manage-pods --runner-id 1000
