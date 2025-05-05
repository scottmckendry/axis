#!/usr/bin/env bash

# 🔍 Backup Selection Helper
# Interactively select a backup timestamp from restic snapshots
# requires: restic, jq, fzf
# https://volsync.readthedocs.io/en/stable/usage/restic/index.html#restore-options

set -euo pipefail

# Colors and formatting
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🔍 Backup Selection Helper${NC}"

# Get secret name from argument or default
echo -ne "  ${GREEN}↳${NC} Enter namespace for restore: "
read -r NAMESPACE
echo -ne "  ${GREEN}↳${NC} Enter PVC name to restore: "
read -r PVC_NAME
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
		echo "Secret $SECRET_NAME not found in namespace $NAMESPACE" >&2
		exit 1
	fi
done

echo -e "  ${GREEN}↳${NC} Removing any stale locks..."
restic unlock
echo -e "  ${GREEN}↳${NC} Loading available backups..."

# Fetch and format backup list
backup_list=$(restic snapshots --json |
	jq -r '.[] | "\(.time) [\(.summary.total_bytes_processed/1024/1024 | floor)MB, \(.summary.total_files_processed) files] \(.paths[0])"')

[ -z "$backup_list" ] && {
	echo "No backups found"
	exit 1
}

# Select from the backup list
selected=$(echo "$backup_list" |
	fzf --height 40% --tac)

# Extract just the timestamp part (everything before the first '[')
timestamp=$(echo "$selected" | cut -d'[' -f1 | xargs)

# Round up to the nearest minute for the "restoreAsOf" option
adjusted=$(date -d "$timestamp + 1 minute" +"%Y-%m-%dT%H:%M:00Z")

# Cleanup environment
for prop in "${SECRET_PROPS[@]}"; do
	unset "$prop"
done

if [[ -z "$adjusted" ]]; then
	echo "No valid date selected. Exiting."
	exit 1
fi

echo -e "  ${GREEN}↳${NC} Selected backup timestamp: ${BOLD}$adjusted${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# replicate hyphens in namespace to underscores for compatibility with env var lookups in child task
# e.g. home-assistant -> volsync_restore_home_assistant
TASK_NAME="${NAMESPACE}-${PVC_NAME}"
task volsync:restore-${TASK_NAME//-/_} -- --restore-date "$adjusted"
