# PostgreSQL cluster management recipes

# Variables
cluster_name := "postgresql-cluster"
cluster_namespace := "databases"
cluster_manifest := "kubernetes/platform/databases/postgresql/cluster.yaml"

# Recover PostgreSQL cluster to a point in time (interactive)
pg-recover:
    ./scripts/pg-recover.sh {{cluster_name}} {{cluster_namespace}} {{cluster_manifest}}

# Monitor PostgreSQL cluster recovery progress
pg-monitor:
    @echo "👀 Watching cluster..."
    kubectl get cluster {{cluster_name}} -n {{cluster_namespace}} -w

# Restore manifest to git state after recovery is complete
pg-restore-after-recovery:
    @echo "🔄 Restoring manifest to original state..."
    git restore {{cluster_manifest}}
    kubectl apply -f {{cluster_manifest}}
