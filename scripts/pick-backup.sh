#!/usr/bin/env bash

# 🔍 Backup Selection Helper
# Interactively select a backup timestamp from restic snapshots
# requires: restic, jq, fzf
# https://volsync.readthedocs.io/en/stable/usage/restic/index.html#restore-options

set -euo pipefail

# Get secret name from argument or default
read -rp "Enter the name for restore: " NAMESPACE
SECRET_NAME="restic-$NAMESPACE"

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

# Select and format backup timestamp
selected=$(restic snapshots --json 2>/dev/null |
	jq -r '.[] | "\(.time) [\(.summary.total_bytes_processed/1024/1024 | floor)MB, \(.summary.total_files_processed) files] \(.paths[0])"' |
	fzf --height 40% --tac |
	awk '{print $1}')

# Round up to the nearest minute for the "restoreAsOf" option
# "An RFC-3339 timestamp which specifies an upper-limit on the snapshots that we should be looking through when preparing to restore. Snapshots made after this timestamp will not be considered."
adjusted=$(date -d "$selected + 1 minute" +"%Y-%m-%dT%H:%M:00Z")

# Cleanup environment
for prop in "${SECRET_PROPS[@]}"; do
	unset "$prop"
done

if [[ -z "$adjusted" ]]; then
	echo "No valid date selected. Exiting."
	exit 1
fi

task volsync:restore-$NAMESPACE -- --restore-date "$adjusted"
