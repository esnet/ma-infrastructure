#!/usr/bin/env bash
./preflight-check.sh
# ./bootstrap-cluster.sh
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace \
     -f argo_values.yml \
     --version 8.6.3 --wait

helm install esnet esnet/gateway-tls -n argocd --version v0.1.2 -f ../argocd-values/ma-infrastructure-474617/argocd_tls_values.yml  --wait
kubectl -n argocd apply -f argocd_route.yaml
