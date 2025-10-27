#!/bin/bash
#!/bin/bash

# Check if parameter was passed
if [ -z "$1" ]; then
    echo "Error: Project parameter is required" >&2
    echo "Usage: $0 <project>" >&2
    exit 1
fi

project=$1
# First, get the current project configuration
kubectl get appproject $project -n argocd -o yaml > local-project-backup.yaml

# Then apply the updated project with cluster resource permissions
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: $project
  namespace: argocd
spec:
  # Allow all cluster-scoped resources (simplest approach)
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'

  # Keep existing destination settings
  destinations:
  - namespace: '*'
    server: '*'

  # Keep existing source repos
  sourceRepos:
  - '*'
EOF

# Verify the update
#kubectl get appproject $project -n argocd -o yaml

# Now sync cert-manager
#argocd app sync cert-manager
