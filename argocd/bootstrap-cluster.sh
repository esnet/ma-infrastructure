#!/usr/bin/env bash
helm repo add external-secrets https://charts.external-secrets.io || echo "external-secrets already exists"
helm repo add jetstack https://charts.jetstack.io || echo "jetpack already exists"
helm repo add esnet https://raw.githubusercontent.com/esnet/ma-helm-charts/main/ || echo "esnet already exists"
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.19.0 --set  crds.enabled=true --set config.enableGatewayAPI=true --wait
helm install external-secrets external-secrets/external-secrets -n secrets --version v0.20.3  --create-namespace --wait
#helm install -n monitoring prometheus oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --create-namespace
