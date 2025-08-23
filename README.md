<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://scottmckendry.tech/img/logo/icon2transparent.png">
    <img src="https://scottmckendry.tech/img/logo/icon1transparent.png" height="100">
  </picture>
  <h1 align="center">AXIS</h1>
  <p align="center">
    <i><b>A</b>utomated e<b>X</b>perimental <b>I</b>nfrastructure <b>S</b>ystem</i>
  </p>
</p>

---

Mono-repo for my GitOps-driven K8s homelab 🏠

## 🧭 Overview

AXIS is my GitOps Kubernetes cluster home lab. The repository contains all cluster manifests, Helm repositories and releases, Talos OS configuration, backup policies, and secrets management tooling via SOPS.

- **GitOps**: Flux v2 manages state from this repo
- **Manifests**: Kustomize overlays per app/namespace under `kubernetes/`
- **OS**: Talos for immutable Kubernetes nodes (see `talos/`)
- **Control plane**: 3 Talos control-plane nodes in HA behind a VIP (MetalLB)
- **Ingress**: Traefik + cert-manager (Let’s Encrypt via Cloudflare)
- **Storage**: democratic-csi (TrueNAS) and local-path-provisioner
- **Monitoring**: kube-prometheus-stack, Grafana, Loki/Promtail, Alertmanager
- **Backups**: VolSync (restic) with Backblaze B2
- **Secrets**: SOPS with age

## 🔐 Secrets management (SOPS + age)

Common operations:

```sh
# Decrypt secrets
task sops:decrypt

# Re-encrypt all secrets
task sops:encrypt

# Low-level helper (used by the tasks)
scripts/sops.sh encrypt|decrypt
```

Secret file conventions:

- Secrets end with `.secret.sops.yaml`
- Decrypted secrets end with `.secret.yaml` (wildcard in `.gitignore`)

<img width="1666" height="580" alt="image" src="https://github.com/user-attachments/assets/df4b5cb1-43b8-4839-9b55-26e5c2e4ab25" />

## ♻️ Backups and restores (VolSync)

VolSync is used to snapshot and synchronize PVCs to object storage (Backblaze B2). Each app declares its backup policy under its directory, typically `backup/` with a `backblaze.secret.sops.yaml` for credentials and a `backup.yaml` defining ReplicationSource/ReplicationDestination.

- Configure credentials in the corresponding `backblaze.secret.sops.yaml` (encrypted with SOPS)
- Validate VolSync resources with kustomize/kubeconform as usual

Operational tasks:

```sh
# Interactive restore workflow
task volsync:interactive-restore

# App-specific restore shortcuts (if defined)
task volsync:restore-<name>
```

Example backup locations in this repo:

- `kubernetes/home-assistant/backup/`
- `kubernetes/media/*/backup/`
- `kubernetes/actual/backup/` and `kubernetes/ccinvoice/backup/`

Notes:

- Restores will temporarily scale down workloads and restore PVC contents
- Ensure network egress for B2 and that credentials are valid

<img width="1051" height="808" alt="image" src="https://github.com/user-attachments/assets/f16ad368-75b2-4224-a2c2-8ccf0ebd44ad" />

## 🛡️ Talos lifecycle and upgrades

Talos is configured under `talos/` with patches in `talos/patches/`. Use Taskfile helpers for generating machine configs, applying changes, and upgrading node images.

Common operations:

```sh
# Generate Talos machine configs from image schematic and patches
task talos:generate

# Apply generated configs to the cluster
task talos:apply

# Upgrade Talos across control plane and workers
task talos:upgrade
```

Patches of interest in `talos/patches/` include networking (VIP, DHCP), storage mounts for local-path-provisioner, and permissions for running certain workloads on control-plane nodes.
