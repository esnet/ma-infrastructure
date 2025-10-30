#!/usr/bin/env bash
set -e
# Check if parameter was passed
if [ -z "$1" ]; then
    echo "Error: Project parameter is required" >&2
    echo "Usage: $0 <project>" >&2
    exit 1
fi
project=$1
project_name=$(echo $project | sed -E 's/-[0-9]+//')
Echo "Connecting to ArgoCD Cluster..."
gcloud container clusters get-credentials argocd-prod --region us-central1 --project ma-infrastructure-474617
argocd proj create $project --description $project_name
if kubectl create ns $project 2>/dev/null; then
  project_exists=false
  echo "Namespace created"
else
  project_exists=true
  echo "Namespace already exists"
fi
echo "Allowing all sources"
argocd proj add-source $project "*"
echo "Limiting App definition to project namespace and argocd"
argocd proj add-source-namespace $project $project
argocd proj add-source-namespace $project argocd
echo "Fixing resource kind allow list"
argocd proj allow-cluster-resource $project "*" "*"
echo "Fixing Destination"
argocd proj add-destination $project "*" "*"
echo "Patching ArgoCD to add new namespace"
if [ "$project_exists" = false ]; then
  CURRENT=$(kubectl -n argocd get configmap argocd-cmd-params-cm -o jsonpath='{.data.application\.namespaces}')
  kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p "{\"data\":{\"application.namespaces\":\"${CURRENT},$project\"}}"
  echo "Restarting Deploymens"
  kubectl -n argocd rollout restart deployment argocd-server
  kubectl -n argocd rollout restart deployment argocd-repo-server
  kubectl -n argocd rollout restart statefulset argocd-application-controller
fi
echo "kubectl edit deployment -n argocd argocd-applicationset-controller and update the following lines with the new namespace:"
echo "args:"
echo " - --applicationset-namespaces=argocd,ma-infrastructure-474617,stardust-development-464714"
echo " - --allowed-scm-providers=https://github.com,https://gitlab.com"
