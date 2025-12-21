
---

# 🚀 **Kubernetes DaemonSet — Complete Notes (MD Format)**

## 📘 **Definition**

A **DaemonSet** in Kubernetes ensures that **one Pod runs on every (or selected) node** in the cluster.
It is primarily used to deploy **cluster-level services** such as:

* Logging agents
* Monitoring agents
* Node-level storage tools
* Network plugins

A DaemonSet guarantees that **as nodes are added or removed**, the required Pods are automatically added or cleaned up.

---

# 🔥 **Why Do We Need DaemonSets?**

## 🧩 **The Challenge**

In modern applications, **monitoring and logging** are essential.
If you deploy logging/monitoring Pods manually:

* You must deploy Pods every time new nodes are added.
* Manual deployment is error-prone.
* Scaling nodes becomes painful.
* Missing agents = missing logs = risky production incidents.

---

# ✅ **The Solution — DaemonSet**

DaemonSet automatically ensures:

* A **copy of the Pod exists on all nodes**, or selected nodes.
* When new nodes join, Pods appear automatically.
* When nodes are removed, Pods are removed as well.

---

# ⭐ **Key Features of DaemonSet**

### ✔ **Runs one Pod per node**

No `replicas` in DaemonSet — the count = number of nodes matching selector.

### ✔ **Node Affinity**

Deploy only on specific nodes (e.g., worker nodes, test nodes).

### ✔ **Rolling Updates**

DaemonSets support **seamless rolling updates** without downtime.

### ✔ **Resource Optimization**

Useful for lightweight Pods that must run everywhere.

---

# 🛠 **Create a DaemonSet Using Command**

```bash
kubectl create daemonset ds-name --image=image-name
```

---

# 📝 **DaemonSet Manifest Example**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: myds
spec:
  selector:
    matchLabels:
      app: monitor
  template:
    metadata:
      labels:
        app: monitor
    spec:
      containers:
      - name: cont-1
        image: fluentd:latest
        ports:
        - containerPort: 80
```

### Apply the YAML:

```bash
kubectl apply -f daemonset.yaml
```

🔎 **NOTE:**
DaemonSets do **NOT** use replicas — because it always creates **1 Pod per node**.

---

# 🧵 **Real-Time Example: Deploy Logging Agent Only on Test Nodes**

## 🎯 **Scenario**

You have:

* A hybrid cluster
* Some nodes labeled `env=test`
* Want logging Pods **only on test nodes**
* Avoid running logging Pods on production nodes

---

# 🏆 **Solution: DaemonSet with Node Affinity**

DaemonSet + Node Affinity ensures Pods run **only on selected nodes**.

---

## Step 1 — Label the Test Nodes

```bash
kubectl label node test-node-1 env=test
kubectl label node test-node-2 env=test
```

Check labels:

```bash
kubectl get nodes --show-labels
```

---

## Step 2 — Create DaemonSet YAML (With Node Affinity)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: my-logging-agent
spec:
  selector:
    matchLabels:
      app: log
  template:
    metadata:
      labels:
        app: log
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: env
                operator: In
                values:
                - test
      containers:
      - name: cont-1
        image: fluent/fluentd:v1.14.6
```

---

## Step 3 — Deploy the DaemonSet

```bash
kubectl apply -f logging-pod.yaml
```

---

## Step 4 — Verify

### DaemonSets list:

```bash
kubectl get daemonset
```

### Where Pods are running:

```bash
kubectl get pods -o wide
```

✔ Pods will be scheduled **only on nodes** labeled with `env=test`.

---

# 🏢 **Business Impact**

### 💰 **Cost Optimization**

Avoids wasting resources on production nodes.

### 🔐 **Environment Isolation**

Test logs collected separately → easier debugging.

### ⚙ **Full Automation**

New test nodes automatically receive logging Pods.

### 🧘 **Operational Stability**

Zero manual intervention → fewer errors → more consistency.

---

# 🎯 **Final Summary**

| Concept                  | Explanation                                     |
| ------------------------ | ----------------------------------------------- |
| **DaemonSet**            | Ensures one Pod per node                        |
| **Use Cases**            | Logging, monitoring, networking, storage agents |
| **No Replicas**          | Pod count = number of nodes                     |
| **Node Affinity**        | Run Pods only on selected nodes                 |
| **Auto-Scaling Support** | Pods appear automatically on new nodes          |

---


