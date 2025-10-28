## Managing Secrets

Assuming kubeseal is installed in the namespace:`sealed-secrets`

1. Create your secret manifest:

```sh
cat <<EOF > vm_token.yaml
 >  apiVersion: v1
kind: Secret
metadata:
  name: vmauth-write-token
  namespace: vm
type: Opaque
stringData:
  write-token: "$TOKEN"
EOF
```

2. Create your kubeseal

```sh
kubeseal --controller-namespace=sealed-secrets \
  --controller-name=sealed-secrets \
  --format=yaml \
  < vmauth-secret-temp.yaml > vmauth-sealed-secret.yaml
```

3. Add vmauth-sealed-secret.yaml to your git repo and apply it as raw manifest part your argocd depolyment
