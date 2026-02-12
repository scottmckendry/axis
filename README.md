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

<p align="center">
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fscottmckendry%2Faxis%2Fmain%2Fkubernetes%2Fplatform%2Ftuppr%2Ftalos-upgrade.yaml&query=%24.spec.talos.version&logo=talos&logoColor=white&label=talos&color=blue" alt="Talos" />
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fscottmckendry%2Faxis%2Fmain%2Fkubernetes%2Fplatform%2Ftuppr%2Fkubernetes-upgrade.yaml&query=%24.spec.kubernetes.version&logo=kubernetes&logoColor=white&label=kubernetes&color=blue" alt="Kubernetes" />
  <a href="https://status.axis.scottmckendry.tech"><img src="https://status.axis.scottmckendry.tech/api/v1/endpoints/connectivity_cloudflare/uptimes/30d/badge.svg" alt="Uptime" /></a>
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
just decrypt

# Re-encrypt all secrets
just encrypt

# Low-level helper (used by the recipes)
scripts/sops.sh encrypt|decrypt
```

Secret file conventions:

- Secrets end with `.secret.sops.yaml`
- Decrypted secrets end with `.secret.yaml` (wildcard in `.gitignore`)

<img width="1666" height="580" alt="image" src="https://github.com/user-attachments/assets/df4b5cb1-43b8-4839-9b55-26e5c2e4ab25" />

## 🐘 CloudNative Postgres

CloudNative Postgres is used everywhere I possibly can for persistent databases.

### Backup and restore

All backups are configured with the CNPG Barman Cloud plugin to Backblaze B2. WAL archiving allows for point-in-time recovery with small RPO/RTO.

## ♻️ Backups and restores (VolSync)

VolSync is used to snapshot and synchronize PVCs to object storage (Backblaze B2). Each app declares its backup policy under its directory, typically `backup/` with a `backblaze.secret.sops.yaml` for credentials and a `backup.yaml` defining ReplicationSource/ReplicationDestination.

- Configure credentials in the corresponding `backblaze.secret.sops.yaml` (encrypted with SOPS)
- Validate VolSync resources with kustomize/kubeconform as usual

Operational tasks:

```sh
# Interactive restore workflow
just restore
```

Notes:

- Restores will temporarily scale down workloads and restore PVC contents
- Ensure network egress for B2 and that credentials are valid

<img width="1051" height="808" alt="image" src="https://github.com/user-attachments/assets/f16ad368-75b2-4224-a2c2-8ccf0ebd44ad" />

## 🛡️ Talos/Kubernetes cluster management

Talos is configured under `talos/` with patches in `talos/patches/`. Use justfile recipes for generating machine configs and applying them to the cluster.

Common operations:

```sh
# Generate Talos machine configs from image schematic and patches
just generate

# Apply generated configs to the cluster
just apply
```

### Upgrades

Managed via [tuppr](https://github.com/home-operations/tuppr) 🩵
