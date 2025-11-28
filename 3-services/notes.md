# Exposing Kubernetes Services — Notes (from the provided article)


---

## What is a Service?

* A **Service** is a virtual load balancer for a group of Pods.
* It routes incoming requests to matching Pods using a **Service selector** and the Pods’ **labels**.
* Services also handle internal routing between Pods.

---

## Service types

### 1. ClusterIP

* **Purpose**: expose Pods **only inside the cluster** (not accessible from outside).
* Common use-case: databases (you usually don’t expose DB endpoints externally).
* Service selects Pods by label (e.g., `layer: db`) — only matching Pods receive traffic.

**Example**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-db
spec:
  selector:
    layer: db
  type: ClusterIP
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
```

---

### 2. NodePort

* **Purpose**: expose the Service on each node’s IP at a static port (`<NodeIP>:<NodePort>`), making it accessible from outside via any node’s IP.
* **Node IP** = worker node IP.
* **NodePort range**: `30000–32767` (default). If you don’t specify `nodePort`, the system assigns one in that range.
* Each cluster node proxies the `nodePort` to the Service `port`, which forwards to the Pod `targetPort`.

  * **port** = Service port
  * **targetPort** = Pod container port
  * **nodePort** = external port on node

**Example**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devops
spec:
  type: NodePort
  selector:
    app: swiggy
  ports:
    - port: 8080
      targetPort: 80
      nodePort: 30001
```

---

### 3. LoadBalancer

* **Purpose**: request a cloud-provider load balancer (AWS/Azure/GCP/etc.) and expose the Service through that LB.
* The cloud provider creates the load balancer and assigns a DNS name to the Service.
* Traffic flows: **external load balancer → Service → Pods**.
* Cloud provider is responsible for load balancer availability and scaling.

**Example**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mustafa
spec:
  type: LoadBalancer
  selector:
    app: swiggy
  ports:
    - port: 8080
      targetPort: 80
```

---

## Important notes / reminders (from article)

* Services match requests to Pods via **selector (in Service)** and **labels (in Pods)**.
* Choose the Service type based on application requirements and infrastructure:

  * `ClusterIP` — internal-only access (e.g., DB).
  * `NodePort` — quick external access via node IPs and ports (uses port range `30000–32767`).
  * `LoadBalancer` — cloud-managed public LB with DNS (provider manages LB availability/scaling).
* Understanding `port`, `targetPort`, and `nodePort` is essential for request flow:

  * Request → `nodePort` → Service `port` → Pod `targetPort`.

---

## Conclusion (article summary)

* Exposing services is critical for making applications accessible inside/outside the cluster.
* Each method (ClusterIP, NodePort, LoadBalancer) has trade-offs — pick based on your infra and scalability needs.

---

If you want, I can convert this into a one-page printable cheatsheet (MD → PDF) or add examples showing how to create matching Pods for each Service type. Which would you prefer?
