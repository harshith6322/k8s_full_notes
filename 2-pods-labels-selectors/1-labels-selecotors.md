# Labels, Selectors & NodeSelectors — concise notes (Markdown)
# https://mustafa-k8s.hashnode.dev/labels-selectors-and-node-selectors

---

# Labels

* **What**: key=value pairs attached to Kubernetes objects (Pods, Nodes, Services, Deployments, etc.).
* **Purpose**: organize/filter/group resources (like tags in cloud providers).
* **Where to use**: environment, team, tier, region, hardware feature, etc.

### Syntax rules (short)

* Key format: optionally `prefix/name` where `prefix` is a DNS subdomain and `name` is the label name.
* Prefix length ≤ 253 chars, name ≤ 63 chars.
* Reserved prefixes: `kubernetes.io/`, `k8s.io/` (avoid using these for custom labels).
* Values ≤ 63 chars; value can be empty (but typical practice is use non-empty).
* Use simple characters: alphanumerics, `-`, `_`, `.` — must start/end with alnum when non-empty.

### Common commands

* Show labels for pods:

```bash
kubectl get pods --show-labels
```

* List pods with a label:

```bash
kubectl get pods -l env=testing
```

* Add (imperative) a label to an existing pod:

```bash
kubectl label pod <pod-name> Location=India
```

* Overwrite an existing label:

```bash
kubectl label pod <pod-name> foo=bar --overwrite
```

* Remove a label:

```bash
kubectl label pod <pod-name> foo-
```

---

# Selectors (label-selectors)

* **What**: ways to filter resources by labels. Used by `kubectl` and by controllers (Services, ReplicaSets, Deployments, etc.) to choose matching objects.
* Two forms supported by the API:

  1. **Equality-based** — operators `=`, `==`, `!=`.
     Examples: `env=prod`, `tier!=frontend`
  2. **Set-based** — operators `In`, `NotIn`, `Exists`, `DoesNotExist`.
     Examples:

  * `env in (testing,development)`
  * `zone notin (us-east-1,us-west-2)`
  * `key` (Exists)

### `kubectl` examples

```bash
# equality
kubectl get pods -l env=testing

# inequality
kubectl get pods -l 'department!=DevOps'

# set-based (shell quoting required on many shells)
kubectl get pods -l 'env in (testing,development)'

# notin
kubectl get pods -l 'Location notin (India,US)'

# delete by selector (careful!)
kubectl delete pod -l 'Location!=China'
```

> Tip: quote the selector expression in your shell to avoid parentheses/space issues.

### Selector in resource YAML

* Simple `matchLabels` (exact matches):

```yaml
selector:
  matchLabels:
    app: my-app
    tier: frontend
```

* More expressive `matchExpressions`:

```yaml
selector:
  matchExpressions:
    - key: tier
      operator: In
      values:
        - frontend
        - cache
```

* `matchLabels` is syntactic sugar for a set of equality requirements; `matchExpressions` lets you express `In/NotIn/Exists`.

---

# NodeSelector

* **What**: basic scheduling constraint placed in a Pod spec to require the Pod run only on nodes that have matching node labels.
* **How it works**: you label nodes, then a Pod with a `nodeSelector` will only be scheduled on nodes that have **all** the label key/value pairs in `nodeSelector`.

### Example — label node, then schedule pod

```bash
# label a node (run on control plane or kubeconfig machine)
kubectl label node <node-name> node-id=node1
```

Pod manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: my-app
spec:
  nodeSelector:
    node-id: node1
  containers:
    - name: cont-1
      image: shaikmustafa/dm
      ports:
        - containerPort: 80
```

* If **no** node matches all `nodeSelector` labels, the Pod stays in **Pending**.
* `nodeSelector` only supports exact-match semantics — no preferences, no `In/NotIn`, and no soft weighting.

---

# When to use nodeSelector vs alternatives

* **nodeSelector**: super simple exact-match requirements. Good for very small clusters and strict hardware constraints.
* **Node Affinity** (recommended for most advanced use cases): supports `requiredDuringSchedulingIgnoredDuringExecution` (hard) and `preferredDuringSchedulingIgnoredDuringExecution` (soft/preferred). Use nodeAffinity when you need OR logic, preferences, or expressions.
* **Taints & Tolerations**: use when you want to prevent most pods from landing on a node unless they tolerate the taint (good for isolating nodes).
* Combined usage: `nodeAffinity` + `taints/tolerations` covers most advanced scheduling scenarios.

---

# Quick cheatsheet — operators & shell notes

* Equality: `key=value`, `key==value`, `key!=value`
* Set: `key in (a,b)`, `key notin (x,y)`, `key` (exists), `!key` or `key does not exist` (use `DoesNotExist` in API)
* In shell, wrap complex selectors in single or double quotes:
  `kubectl get pods -l 'env in (testing,development)'`

---


## Minimal example — combined

```yaml
# Node label (imperative)
# kubectl label node worker-1 node-id=node1

apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: my-app
    env: testing
spec:
  nodeSelector:
    node-id: node1
  containers:
    - name: web
      image: nginx
      ports:
        - containerPort: 80
```

---

