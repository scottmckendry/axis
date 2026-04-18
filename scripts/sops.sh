#!/usr/bin/env bash

# 🔐 SOPS Encryption/Decryption Helper
# Manages secret files in the repository using SOPS

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
WORKSPACE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sops-workspace"

check_dependencies() {
	local missing_deps=()
	command -v sops >/dev/null 2>&1 || missing_deps+=("sops")
	command -v age >/dev/null 2>&1 || missing_deps+=("age")
	command -v secret-tool >/dev/null 2>&1 || missing_deps+=("secret-tool")

	if [ ${#missing_deps[@]} -ne 0 ]; then
		echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
		exit 1
	fi
}

load_age_key() {
	local key
	key="$(secret-tool lookup app sops type age-key 2>/dev/null)"

	if [ -z "$key" ]; then
		echo -e "${RED}Error: Age key not found in keyring. Store it with:${NC}" >&2
		echo -e "  secret-tool store --label=\"age secret key\" app sops type age-key" >&2
		exit 1
	fi

	export SOPS_AGE_KEY="$key"
}

ensure_workspace() {
	mkdir -p "$WORKSPACE"
	chmod 700 "$WORKSPACE"
}

usage() {
	cat <<EOF
${BLUE}🔐 SOPS Encryption/Decryption Helper${NC}

Usage:
    $(basename "$0") <command>

Commands:
    encrypt     Encrypt *.secret.yaml files from workspace back to repo
    decrypt     Decrypt all *.secret.sops.yaml files into workspace (tmpfs)

Workspace: $WORKSPACE (tmpfs — cleared on reboot)

EOF
	exit 1
}

if [ $# -ne 1 ] || [[ ! "$1" =~ ^(encrypt|decrypt)$ ]]; then
	usage
fi

MODE="$1"

check_dependencies
load_age_key
ensure_workspace

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$MODE" = "encrypt" ]; then
	echo -e "${BOLD}🔒 Encrypting secret files from workspace...${NC}"
	find "$WORKSPACE" -type f -name "*.secret.yaml" | while read -r file; do
		rel="${file#$WORKSPACE/}"
		dest="$REPO_ROOT/${rel/.secret.yaml/.secret.sops.yaml}"
		if [ ! -f "$dest" ] || ! sops --decrypt "$dest" 2>/dev/null | diff - "$file" >/dev/null 2>&1; then
			echo -e "  ${GREEN}↳${NC} Encrypting $rel"
			sops --encrypt "$file" >"$dest"
		fi
		plain_link="$REPO_ROOT/$rel"
		[ -L "$plain_link" ] && rm -f "$plain_link"
	done
else
	echo -e "${BOLD}🔓 Decrypting secret files into workspace...${NC}"
	find "$REPO_ROOT" -type f -name "*.secret.sops.yaml" | while read -r file; do
		rel="${file#$REPO_ROOT/}"
		dest="$WORKSPACE/${rel/.secret.sops.yaml/.secret.yaml}"
		mkdir -p "$(dirname "$dest")"
		chmod 700 "$(dirname "$dest")"
		echo -e "  ${GREEN}↳${NC} Decrypting $rel"
		sops --decrypt "$file" >"$dest"
		chmod 600 "$dest"
		link="$REPO_ROOT/${rel/.secret.sops.yaml/.secret.yaml}"
		ln -sf "$dest" "$link"
	done
	echo -e "\n  ${BOLD}Workspace:${NC} $WORKSPACE"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
