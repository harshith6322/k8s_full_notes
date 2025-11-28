
---

````markdown
# 🚀 Argo CD Installation and Usage Guide (Kind + Helm + CLI)

## 🧠 2) Install Argo CD (via manifests)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## 🔍 3) Inspect cluster and Argo CD resources

```bash
kubectl get ns
kubectl get svc -n argocd
kubectl get po -n argocd
kubectl get all -n argocd
```

---

## ⚙️ 4) Edit argocd-server service if needed

*Uncomment below line if you need to edit service type (LoadBalancer/NodePort)*

```bash
 kubectl edit svc argocd-server -n argocd
```

---

## 🌐 5) Port-forward Argo CD server to localhost:8080

**Option 1 — Foreground:**

```bash
kubectl port-forward svc/argocd-server -n argocd --address 0.0.0.0 8080:80
```

**Option 2 — Background (persists across logout):**

```bash
nohup kubectl port-forward svc/argocd-server -n argocd --address 0.0.0.0 8080:80 > portforward.log 2>&1 &
```

---

## 🔑 6) Get the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

---

## 🩺 7) Useful diagnostics

```bash
docker ps
ss -tlnp | grep 8080 || true
```

---

# 🧰 Argo CD CLI - Install, Login, and Create App

## 🪄 1) Install argocd CLI (linux amd64)

```bash
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/download/v${VERSION}/argocd-linux-amd64"
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm -f argocd-linux-amd64
```

---

## 🧾 2) Verify client

```bash
argocd version --client
```

---

## 🌍 3) Ensure Argo CD server is reachable

Either port-forward locally (foreground) or run in background:

```bash
kubectl port-forward svc/argocd-server -n argocd --address 0.0.0.0 8080:80 &
```

Or use the cluster IP/hostname (example):

```bash
SERVER=52.206.194.87:8080
```

Usually for local setup:

```bash
SERVER=localhost:8080
```

---

## 🔐 4) Get initial admin password

```bash
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Admin password: $ADMIN_PASSWORD"
```

---

## 🔑 5) Login with argocd CLI (use --insecure if server has self-signed cert)

```bash
argocd login $SERVER --username admin --password "$ADMIN_PASSWORD" --insecure
```

---

## 📦 6) Create example app (Guestbook)

```bash
argocd app create guestbook \
    --repo https://github.com/argoproj/argocd-example-apps.git \
    --path guestbook \
    --dest-namespace default \
    --dest-server https://kubernetes.default.svc \
    --directory-recurse
```

---

## 🔄 7) Sync and check status

```bash
argocd app sync guestbook
argocd app get guestbook
argocd app list
```

---

# 🧭 Argo CD Helm Setup

## 📚 1) Add/refresh Helm repo

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

---

## ⚙️ 2) Install Argo CD via Helm (idempotent, waits for readiness)

Ensure namespace exists:

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
```

Install or upgrade Helm release:

```bash
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait --timeout 5m
```

---

## 🧩 Optional: Use custom values

```bash
# helm upgrade --install argocd argo/argo-cd -n argocd --wait --timeout 5m -f my-values.yaml
```

---

## 🔑 4) Get initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

---

✅ **End of ArgoCD Setup Guide**

```

---

Would you like me to save this as a downloadable **`.md` file** (e.g., `argocd-setup.md`)? I can generate it instantly so you can keep it in your DevOps notes repo.
```
