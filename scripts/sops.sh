#!/usr/bin/env bash

# 🔐 SOPS Encryption/Decryption Helper
# Manages secret files in the repository using SOPS

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
${BLUE}🔐 SOPS Encryption/Decryption Helper${NC}

Usage: 
    $(basename "$0") <command>

Commands:
    encrypt     Encrypt all *.secret.yaml files to *.secret.sops.yaml
    decrypt     Decrypt all *.secret.sops.yaml files to *.secret.yaml

EOF
    exit 1
}

# Validate arguments
if [ $# -ne 1 ] || [[ ! "$1" =~ ^(encrypt|decrypt)$ ]]; then
    usage
fi

MODE="$1"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$MODE" = "encrypt" ]; then
    echo -e "${BOLD}🔒 Encrypting secret files...${NC}"
    # Find all unencrypted secret files and encrypt them if encrypted version doesn't exist or is different
    find . -type f -name "*.secret.yaml" | while read -r file; do
        encrypted_file="${file/.secret.yaml/.secret.sops.yaml}"
        if [ ! -f "$encrypted_file" ] || ! sops --decrypt "$encrypted_file" 2>/dev/null | diff - "$file" >/dev/null 2>&1; then
            echo -e "  ${GREEN}↳${NC} Encrypting $file -> $encrypted_file"
            sops --encrypt "$file" >"$encrypted_file"
        fi
    done
else
    echo -e "${BOLD}🔓 Decrypting secret files...${NC}"
    # Find all encrypted files and decrypt them
    find . -type f -name "*.secret.sops.yaml" | while read -r file; do
        decrypted_file="${file/.secret.sops.yaml/.secret.yaml}"
        echo -e "  ${GREEN}↳${NC} Decrypting $file -> $decrypted_file"
        sops --decrypt "$file" >"$decrypted_file"
    done
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
