#!/usr/bin/env bash

# 🔄 Kubernetes Volume Restore Helper
# Restores PVC data using VolSync ReplicationDestination

# TODO: suspend flux reconciliations during restore

set -euo pipefail

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default values
NAME=""
NAMESPACE="default"
RESTORE_DATE=""
MANAGE_PODS="false"
RUNNER_ID=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--name)
		NAME="$2"
		shift 2
		;;
	--namespace)
		NAMESPACE="$2"
		shift 2
		;;
	--restore-date)
		RESTORE_DATE="$2"
		shift 2
		;;
	--runner-id)
		RUNNER_ID="$2"
		shift 2
		;;
	--manage-pods)
		MANAGE_PODS="true"
		shift
		;;
	*)
		echo -e "${RED}Error: Unknown parameter: $1${NC}"
		exit 1
		;;
	esac
done

# Validate required parameters
if [[ -z "$NAME" ]]; then
	echo -e "${RED}Error: Required parameters missing!${NC}"
	echo -e "Usage: $0 --name <name> [--namespace <namespace>] [--restore-date <date>] [--runner-id <id>] [--manage-pods]"
	exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🔄 Starting volume restore process...${NC}"

# Stop pods in NAME if requested
if [[ "$MANAGE_PODS" == "true" ]]; then
	echo -e "  ${GREEN}↳${NC} Scaling down deployments in ${BOLD}$NAMESPACE${NC}..."

	# Store current replica counts and scale down
	kubectl get deployment -n "$NAMESPACE" -o json | jq -r '.items[] | "\(.metadata.name) \(.spec.replicas)"' >/tmp/replica-counts.txt
	kubectl get deployment -n "$NAMESPACE" -o name | xargs -r kubectl scale -n "$NAMESPACE" --replicas=0

	# Wait for all pods to stop before proceeding
	while true; do
		pod_count=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
		if [[ "$pod_count" -eq 0 ]]; then
			break
		fi
		echo -ne "  ${GREEN}↳${NC} Waiting for all pods to stop... ($pod_count remaining)\r"
		sleep 5
	done
fi

# Generate ReplicationDestination manifest
echo -e "  ${GREEN}↳${NC} Generating ReplicationDestination manifest..."
cat <<EOF >/tmp/replication-dest.yaml
apiVersion: volsync.backube/v1alpha1
kind: ReplicationDestination
metadata:
  name: ${NAME}-restore
  namespace: ${NAMESPACE}
spec:
  trigger:
    manual: restore-once
  restic:
    repository: restic-${NAMESPACE}-${NAME}
    destinationPVC: ${NAME}
    copyMethod: Direct
    storageClassName: $(kubectl get pvc ${NAME} -n ${NAMESPACE} -o jsonpath='{.spec.storageClassName}')
EOF

# Add runner_id if specified
if [[ -n "$RUNNER_ID" ]]; then
	echo "    moverSecurityContext:" >>/tmp/replication-dest.yaml
	echo "      runAsUser: ${RUNNER_ID}" >>/tmp/replication-dest.yaml
	echo "      runAsGroup: ${RUNNER_ID}" >>/tmp/replication-dest.yaml
	echo "      fsGroup: ${RUNNER_ID}" >>/tmp/replication-dest.yaml
fi

# Add restore date if specified
if [[ -n "$RESTORE_DATE" ]]; then
	echo "    restoreAsOf: \"${RESTORE_DATE}\"" >>/tmp/replication-dest.yaml
fi

# Apply the ReplicationDestination
echo -e "  ${GREEN}↳${NC} Applying ReplicationDestination..."
kubectl apply -f /tmp/replication-dest.yaml

# Wait for restore to complete
echo -e "  ${GREEN}↳${NC} RepicationDestination created. Waiting for restore to complete..."
echo -e "      📝 ${MAGENTA}if this is taking longer than expected, check the ReplicationDestination with the following:"
echo -e "         kubectl describe replicationdestination ${NAME}-restore -n $NAMESPACE ${NC}\n"
echo -ne "  ${GREEN}↳${NC} Checking status"
while true; do
	status=$(kubectl get replicationdestination "${NAME}-restore" -n "$NAMESPACE" -o jsonpath='{.status.latestMoverStatus.result}')
	if [[ "$status" == "Successful" ]]; then
		break
	fi
	echo -n "."
	sleep 5
done
echo -e "\n  ${GREEN}✓${NC} Restore completed successfully!"

# Show logs from the restore
echo -e "\n${BOLD}📋 Restore logs:${NC}"
logs=$(kubectl get replicationdestination "${NAME}-restore" -n "$NAMESPACE" -o jsonpath='{.status.latestMoverStatus.logs}')
echo -e "$logs\n"

# Cleanup ReplicationDestination
echo -e "  ${GREEN}↳${NC} Cleaning up ReplicationDestination..."
kubectl delete -f /tmp/replication-dest.yaml

# Start pods if they were stopped
if [[ "$MANAGE_PODS" == "true" ]]; then
	echo -e "  ${GREEN}↳${NC} Scaling up deployments in ${BOLD}$NAMESPACE${NC}..."
	# Restore original replica counts
	while read -r deploy replicas; do
		kubectl scale -n "$NAMESPACE" deployment/"$deploy" --replicas="$replicas"
	done </tmp/replica-counts.txt
	# Restore original replica counts
	while read -r deploy replicas; do
		kubectl scale -n "$NAMESPACE" deployment/"$deploy" --replicas="$replicas"
	done </tmp/replica-counts.txt
	rm -f /tmp/replica-counts.txt
fi

rm -f /tmp/replication-dest.yaml
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
