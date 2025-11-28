
Here’s your updated version:

````markdown
# Kubernetes (K8s) Notes

## 🔗 Useful Links
- [K8s YAML Generator](https://k8syaml.com/)

---

## 🌐 What is Kubernetes?

Kubernetes (popularly known as **k8s**) is a container orchestration engine that lets you create, delete, and update containers.
created using gloang by google in 2014 and donated to cncf()in 2015 v1 version was relesed for public use

**Useful when:**
- You have Docker images in the registry and want to deploy in a cloud-native fashion  
- You don’t want to worry about patching, crashes (auto-healing)  
- You want autoscaling with simple constructs  
- You want to observe your system in a dashboard  


---

## 🏗️ Architecture of K8s

- **Cluster** → multiple nodes  
- **Nodes** → master node & worker node  
- **Pods** → smallest unit = containers  
- **Multi-container Docker support**

### Master Node (Control Plane)
- API Server  
- etcd  
- kube-scheduler  
- kube-controller-manager  

### Worker Node
- kubelet → ensures containers run in a Pod  
- kube-proxy → network proxy, pod communication  
- Container runtime → runs containers  

---

## 🚀 Creating a K8s Cluster

### 1. Locally (requires Docker)
- **kind** → [Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- **minikube**  

### 2. On Cloud
- GKE  
- AWS EKS  
- azure AKS
- Vultr  

---

## ⚡ Single Node Setup (Kind)

```bash
kind create cluster --name local
docker ps
kind delete cluster -n local
````

---

## ⚡ Multi Node Setup (Kind)

**clusters.yml**

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

**With Port Mapping**

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
- role: worker
- role: worker
```

**Commands**

```bash
kind create cluster --config clusters.yml --name local
kind get clusters
docker ps
cat ~/.kube/config
kind delete cluster -n local
```

---

## 🔧 Kubectl

* CLI tool to talk to K8s API Server
* Install: [Kubectl Install](https://kubernetes.io/docs/tasks/tools/#kubectl)

```bash
kubectl api-resources
kubectl api-versions
kubectl config
kubectl version
kubectl get nodes or no
kubectl describe po or no 
kubectl get nodes --v=8   # see HTTP request
kubectl get pods or po
```

---

## 🟢 Start a Pod

```bash
kubectl run nginx --image=nginx --port=80
kubectl get pods
kubectl get po -o wide or yaml or json
kubectl logs nginx
kubectl delete pod nginx
kubectl delete pod --all
kubectl describe pod nodejs
```

---

## 📄 Kubernetes Manifest

**manifest.yml**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

```bash
kubectl apply -f manifest.yml
kubectl delete pod nginx
```

---

## 📦 ReplicaSet

```bash
kubectl apply -f rs.yml
kubectl get rs
kubectl get pods
kubectl delete pod <pod-name>
kubectl run nginx-pod --image=nginx --labels="app=nginx"
kubectl delete rs nginx-deployment-576c6b7b6
```

---

## 📦 Deployment

```bash
kubectl apply -f deployment.yml
kubectl get deployment
kubectl get rs
kubectl get pod
kubectl delete pod <pod-name>
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
kubectl delete -f deployment.yaml
```

---

## 🌍 Exposing the App (Services)

Types of services:

1. NodePort
2. LoadBalancer
3. ClusterIP

**service.yml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30007
  type: LoadBalancer
```

```bash
kubectl apply -f service.yml
```

---

# Part 2

## 🗂️ Namespaces

```bash
kubectl create namespace backend-team
kubectl get namespaces
kubectl get pods -n my-namespace
```

**deployment-ns.yml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: backend-team
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f deployment-ns.yml
kubectl get deployment -n backend-team
kubectl get pods -n backend-team
kubectl config set-context --current --namespace=backend-team
kubectl get pods
kubectl config set-context --current --namespace=default
```

```

---


```
