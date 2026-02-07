import '.justfiles/postgres.just'
import '.justfiles/talos.just'

_default:
    @just --list

# Interactive PVC restore using volsync - dynamic pvc and backup discovery
restore:
    ./scripts/pick-backup.sh

# Encrypt all secret files with SOPS
encrypt:
    ./scripts/sops.sh encrypt

# Decrypt all secret files with SOPS
decrypt:
    ./scripts/sops.sh decrypt

