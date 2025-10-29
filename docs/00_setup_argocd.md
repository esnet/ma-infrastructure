## Initial Setup

0. Install dependencies:

 - brew install helm kubeseal

1. Install ArgoCD

All the files that are needed should be in argo_init

All the values should already be pre-configured.

```sh
./boostrap.sh
```

will install the following:

 - cert-manager
 - sealed-secrets
 - argo/argo-cd
 - esnet/gateway-tls
 - httproute

2. Get admin password and update it.

```sh
kubectl -n argocd get secrets  argocd-initial-admin-secret -o jsonpath='{.data.password}'| base64 -d
```

3. Login to the argo cd cluster using the CLI tools

```sh
argocd login argo.gc1.mgt.stardust.es.net --grpc-web
## Add any clusters you like.
argocd cluster add gke_esnet-sd-dev_us-central1-c_dev-staging-dashboard --name grafana-staging
```

Once you have added the cluster review the setting and ensure the setting (source, destination and namespaces espcially)

4. Create Project: this might not be needed, but if you have permission issues

If you don't have a project already create one:

./create_project.sh stardust-development-464714

5. Adding a project with bootstrap


```sh
argocd  cluster add gke_ma-infrastructure-474617_us-central1_ch1-otle-mgt --name "ch1-otle-mgt"  --label version="1.0" --label "bootstrap=true" --label "project=ma-infrastructure-474617"
```
