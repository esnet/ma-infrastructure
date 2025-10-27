#!/usr/bin/env bash
set -e  # Exit on error
function setup_repos
{
    helm repo add external-secrets https://charts.external-secrets.io || echo "external-secrets already exists"
    helm repo add secrets https://bitnami-labs.github.io/sealed-secrets|| echo "secrets already exists"
    helm repo add jetstack https://charts.jetstack.io || echo "jetpack already exists"
    helm repo add esnet https://raw.githubusercontent.com/esnet/ma-helm-charts/main/ || echo "esnet already exists"
    helm repo update
}


setup_repos

helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.19.0 --set  crds.enabled=true --set config.enableGatewayAPI=true --wait
helm install sealed-secrets secrets/sealed-secrets -n sealed-secrets --version 2.17.7 --create-namespace --wait
