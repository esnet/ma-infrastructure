#!/bin/bash

# First, get the current project configuration
kubectl get appproject local -n argocd -o yaml > local-project-backup.yaml

# Then apply the updated project with cluster resource permissions
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: local
  namespace: argocd
spec:
  # Allow all cluster-scoped resources (simplest approach)
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'

  # Or be more restrictive - only allow what cert-manager needs:
  # clusterResourceWhitelist:
  # - group: 'rbac.authorization.k8s.io'
  #   kind: 'ClusterRole'
  # - group: 'rbac.authorization.k8s.io'
  #   kind: 'ClusterRoleBinding'
  # - group: 'apiextensions.k8s.io'
  #   kind: 'CustomResourceDefinition'
  # - group: 'admissionregistration.k8s.io'
  #   kind: 'ValidatingWebhookConfiguration'
  # - group: 'admissionregistration.k8s.io'
  #   kind: 'MutatingWebhookConfiguration'

  # Keep existing destination settings
  destinations:
  - namespace: '*'
    server: '*'

  # Keep existing source repos
  sourceRepos:
  - '*'
EOF

# Verify the update
#kubectl get appproject local -n argocd -o yaml

# Now sync cert-manager
#argocd app sync cert-manager
