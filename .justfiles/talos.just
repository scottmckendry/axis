# Talos cluster configuration and management

# Variables
CLUSTER_NAME := "axis"
CLUSTER_VIP := "10.0.10.10"
# renovate: datasource=github-releases depName=siderolabs/talos
TALOS_VERSION := "v1.12.3"
# renovate: datasource=github-releases depName=kubernetes/kubernetes
KUBERNETES_VERSION := "v1.35.0"

# Generate Talos config
generate:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    just sops:decrypt
    mkdir -p rendered/
    PATCHES=$(ls patches/*.yaml 2>/dev/null | sed 's/.*/--config-patch @&/g' | tr '\n' ' ' || echo "")
    IMAGE_SCHEMATIC_ID=$(curl -fsSL -X POST --data-binary @image-schematic.yaml https://factory.talos.dev/schematics | jq -r '.id')
    talosctl gen config {{CLUSTER_NAME}} https://{{CLUSTER_VIP}}:6443 \
        --talos-version {{TALOS_VERSION}} \
        --install-image factory.talos.dev/installer/${IMAGE_SCHEMATIC_ID}:{{TALOS_VERSION}} \
        --with-secrets talos.secret.yaml \
        --output-types controlplane \
        --output rendered/controlplane.yaml \
        --force \
        ${PATCHES}

# Apply Talos config to all nodes
apply: generate
    #!/usr/bin/env bash
    set -euo pipefail
    for node in 10.0.10.11 10.0.10.12 10.0.10.13; do
        just _apply_node ${node}
    done

# Apply Talos config to individual node
_apply_node NODE_IP:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    read -p "Apply configuration to node {{NODE_IP}}? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        talosctl apply -f rendered/controlplane.yaml -n {{NODE_IP}}
        echo ""
    fi

# Upgrade Talos nodes to specified version
upgrade:
    #!/usr/bin/env bash
    set -euo pipefail
    read -p "Upgrade Talos to {{TALOS_VERSION}} across all nodes? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        for node in 10.0.10.11 10.0.10.12 10.0.10.13; do
            just _upgrade_node ${node}
        done
        echo ""
    fi

# Upgrade individual Talos node
_upgrade_node NODE_IP:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    IMAGE_SCHEMATIC_ID=$(curl -fsSL -X POST --data-binary @image-schematic.yaml https://factory.talos.dev/schematics | jq -r '.id')
    talosctl upgrade --nodes {{NODE_IP}} --image factory.talos.dev/installer/${IMAGE_SCHEMATIC_ID}:{{TALOS_VERSION}}

# Upgrade Kubernetes to tracked version
upgrade-k8s:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    read -p "Upgrade Kubernetes to {{KUBERNETES_VERSION}} across all nodes? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        talosctl upgrade-k8s --to {{KUBERNETES_VERSION}} --nodes 10.0.10.11
        echo ""
    fi
