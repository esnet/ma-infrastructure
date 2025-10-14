#!/usr/bin/env bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace --set 'server.extraArgs[0]'="--insecure" --version 8.6.3 --wait
./bootstrap-cluster.sh
