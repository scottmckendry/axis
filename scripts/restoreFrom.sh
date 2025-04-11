#!/usr/bin/env bash

# Get secret name from argument or default
SECRET_NAME="restic-$1"

SECRET_PROPS=(
	AWS_ACCESS_KEY_ID
	AWS_SECRET_ACCESS_KEY
	RESTIC_PASSWORD
	RESTIC_REPOSITORY
)

# Export required variables from kubernetes secret
echo "fetching secret"
for prop in "${SECRET_PROPS[@]}"; do
	if kubectl get secret -n $1 $SECRET_NAME &>/dev/null; then
		value=$(kubectl get secret -n $1 $SECRET_NAME -o jsonpath="{.data.$prop}" | base64 --decode)
		export "$prop=$value"
	else
		echo "Secret $SECRET_NAME not found in namespace $1"
		exit 1
	fi
done

echo "fetching snapshots"
restic snapshots --json | jq -r '.[] | "\(.time) [\(.short_id)] \(.paths[0])"' | fzf --height 40% | awk -F'[\\[\\]]' '{print $2}'

# unset vars
for prop in "${SECRET_PROPS[@]}"; do
	unset "$prop"
done
