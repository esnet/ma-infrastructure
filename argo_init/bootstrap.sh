#!/usr/bin/env bash
./preflight-check.sh
./bootstrap-cluster.sh
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace \
     -f ./value_files/argo.yml \
     --version 8.6.3 --wait

helm install esnet esnet/gateway-tls -n argocd --version v0.1.3 -f ./value_files/gateway_tls.yml  --wait
kubectl -n argocd apply -f argocd_route.yaml
echo "This gives the ApplicationSet controller permissions across all namespaces."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-applicationset-controller
rules:
- apiGroups:
  - argoproj.io
  resources:
  - applications
  - applicationsets
  - appprojects
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - argoproj.io
  resources:
  - applications/status
  - applicationsets/status
  verbs:
  - get
  - update
  - patch
- apiGroups:
  - ""
  resources:
  - secrets
  - configmaps
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-applicationset-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-applicationset-controller
subjects:
- kind: ServiceAccount
  name: argocd-applicationset-controller
  namespace: argocd
EOF
