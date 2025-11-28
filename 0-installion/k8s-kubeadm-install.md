Nice — manual kubeadm-style Kubernetes on EC2 is a great way to learn how the pieces fit together. Below I’ll give a clear, opinionated, **step-by-step guide** (with ready-to-copy commands and cloud-init snippets) to set up a single-control-plane + multiple-worker cluster on AWS EC2. I’ll cover networking, security, control-plane init, CNI, joining workers, HA notes, and troubleshooting tips.

> Assumptions: you’ll use Ubuntu 22.04 LTS (commands targeted at Debian/Ubuntu), have an AWS account, can create EC2 instances and security groups, and are comfortable running commands as `ubuntu` or `root`. I use **kubeadm + containerd** (recommended). If you want commands for another distro, say so and I’ll adapt.

---

# 1) High-level plan

1. Create VPC / subnets (or reuse existing) and security groups.
2. Create an EC2 keypair and launch instances (1 control-plane, N workers).
3. Install prerequisites: disable swap, install containerd, install kubeadm/kubelet/kubectl.
4. Initialize control plane with `kubeadm init`.
5. Install a CNI (e.g., Calico or Flannel) so pods can talk.
6. Join worker nodes with `kubeadm join`.
7. Verify and run a test workload.

---

# 2) Networking & security (what to open)

Create a security group allowing (Control-plane SG):

* **TCP 6443** (kube-apiserver) — from trusted IPs or from worker SG.
* **TCP 2379-2380** (etcd) — if extra control planes or external etcd.
* **TCP 10250** (kubelet API) — allow from control-plane SG.
* **TCP 10251, 10252** (kube-scheduler/controller-manager) — control-plane use.
* **ICMP / SSH** for admin access (port 22).
  For worker nodes allow:
* **TCP 10250** from control-plane SG
* **All traffic between nodes** (pod networking, kube-proxy, etc.). Easiest: allow the cluster CIDR or allow the worker/control-plane SGs to talk to each other on all ports.
* **NodePort range 30000-32767** (if you plan to use NodePort services from outside).

Important: Keep API server (6443) restricted if exposing externally — prefer a private LB or bastion.

---

# 3) EC2 Instance sizing & count

* Control plane: t3.medium or t3.large for dev; 2 vCPU+ and 4GB+ RAM recommended.
* Workers: t3.small/t3.medium depending on workloads.
* Root volume: 30 GB for logs/containers is safe.
* Use the same Ubuntu image for all nodes.

---

# 4) Bootstrap commands (run on every node as root or `ubuntu` with sudo)

Below is a minimal setup script you can run on control-plane **and** workers (except the kubeadm init step which runs only on control-plane). Save as `node-bootstrap.sh` and run with `sudo bash node-bootstrap.sh`.

```bash
#!/bin/bash
set -euo pipefail

# 1) Basic packages
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# 2) Disable swap (kubeadm requirement)
swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 3) Install containerd
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Use systemd cgroup driver (recommended for kubelet)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# 4) Kernel modules & sysctl for networking
modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# 5) Install kubeadm, kubelet, kubectl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 6) Ensure kubelet starts (it will wait until kubeadm configures it)
systemctl enable kubelet && systemctl start kubelet

echo "bootstrap done on $(hostname) ($(hostname -I | awk '{print $1}'))"
```

Run:

* On control-plane: `sudo bash node-bootstrap.sh`
* On each worker: same script

---

# 5) Initialize control plane (run ONCE on control-plane)

Decide a Pod network CIDR depending on your CNI:

* Calico common CIDR: `192.168.0.0/16` (but some choose `10.244.0.0/16` for Flannel).
  Example (single master, no external load balancer):

```bash
# Example: set kubeadm to use a specific pod CIDR for your CNI
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

Important output: after `kubeadm init` it will print:

* How to set up kubeconfig for `kubectl` (copy to $HOME/.kube/config).
* A `kubeadm join ... --token ... --discovery-token-ca-cert-hash ...` command you will use on workers.

Make `kubectl` usable for ubuntu user:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

If you lost the join command, you can create a fresh one:

```bash
# On control plane
kubeadm token create --print-join-command
# or
kubeadm token create mytoken --ttl 24h
kubeadm token create --print-join-command
```

---

# 6) Install a CNI plugin (example: Calico)

After `kubeadm init` and configuring kubeconfig, install a CNI so pods get IPs.

Example — apply Calico (run on control plane with kubectl):

```bash
# from control-plane (kubectl must be configured)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

Or for Flannel:

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

Wait a minute and verify:

```bash
kubectl get pods -n kube-system
```

---

# 7) Join worker nodes

On each worker, run the `kubeadm join ...` command printed earlier by `kubeadm init` (or generated by `kubeadm token create --print-join-command`). Example:

```bash
sudo kubeadm join <CONTROL_PLANE_IP>:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:<hash>
```

After successful join, verify from control-plane:

```bash
kubectl get nodes
kubectl get pods -A
```

---

# 8) Test the cluster

Run a simple nginx deployment and expose it:

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80
kubectl get svc
# Access via any worker's IP and mapped NodePort (kubectl get svc shows port)
```

---

# 9) Recommended extras & hardening

* **Use an internal ELB or NLB** in front of API server for multi-master HA. For HA control plane (3+ masters) kubeadm requires an external load balancer (AWS ALB/NLB) for `--control-plane-endpoint`.
* **Etcd**: for HA, run an external etcd cluster or stacked etcd on control-plane nodes.
* **IAM / AWS access**: kubelets don’t need AWS keys unless you use cloud-controller-manager features (e.g., EBS PVs). For persistent volumes with AWS EBS, install the AWS CCM and CSI driver and provide node IAM roles.
* **Rotate certificates & tokens**: tokens expire; you can create new tokens and keep kubeadm CA certs stored securely.
* **Autoscaling**: use Cluster Autoscaler with node group autoscaling (requires IAM role/config).
* **Backups**: backup `/etc/kubernetes/pki` and etcd snapshots for control-plane recovery.

---

# 10) Control-plane HA (short overview)

If you want a production-like HA control plane:

1. Provision 3 control-plane EC2s.
2. Put an AWS Network Load Balancer (NLB) in front of port 6443 with target group of control-plane nodes (TCP passthrough).
3. Run `kubeadm init` using `--control-plane-endpoint <NLB_DNS>:6443` and add additional control-plane nodes with `kubeadm join --control-plane`.
4. Ensure etcd clustering (stacked or external) and open ports 2379-2380 among control planes.

---

# 11) Troubleshooting tips

* `kubectl get nodes` shows `NotReady` → check `kubectl get pods -n kube-system` and `journalctl -u kubelet` on failing node.
* CNI pods CrashLoopBackOff → wrong `--pod-network-cidr` for CNI or CNI manifest mismatch.
* Worker fails to join: token expired → re-create `kubeadm token create --print-join-command`.
* kubelet complaining about cgroup driver mismatch → ensure containerd uses `systemd` cgroup driver.
* Swap not off → kubeadm refuses to start. Ensure `/etc/fstab` swap entries are commented and `swapoff -a`.

---

# 12) Example cloud-init snippet (control-plane) — use when launching EC2

Put this into the EC2 user data for the **control plane** (adjust hostname & pod CIDR as needed). It runs the earlier bootstrap and then initializes the cluster.

```yaml
#cloud-config
package_update: true
package_upgrade: false
runcmd:
  - [ bash, -c, 'curl -fsSL https://example.com/node-bootstrap.sh -o /tmp/node-bootstrap.sh' ]
  - [ bash, -c, 'chmod +x /tmp/node-bootstrap.sh && sudo /tmp/node-bootstrap.sh' ]
  - [ bash, -c, 'sudo kubeadm init --pod-network-cidr=192.168.0.0/16 | tee /tmp/kubeadm-init.out' ]
  - [ bash, -c, 'mkdir -p /home/ubuntu/.kube && sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config && sudo chown 1000:1000 /home/ubuntu/.kube/config' ]
  - [ bash, -c, 'sudo -u ubuntu kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml' ]
```

(Replace the curl URL with your bootstrap script location, or embed the entire bootstrap in `runcmd`.)

---

# 13) Useful commands summary

* Create join command: `kubeadm token create --print-join-command`
* Reset a node: `sudo kubeadm reset -f` and cleanup CNI dirs (e.g., `/var/lib/cni/`, `/var/lib/kubelet/*`).
* Get kubeadm version: `kubeadm version`
* View logs: `journalctl -u kubelet -b` or `kubectl -n kube-system logs <pod>`

---

# 14) Final notes & recommendations

* For a production cluster on AWS it’s usually better to use managed solutions (EKS) or tools that manage HA (kops, eksctl, Terraform modules). But manual kubeadm is excellent for learning internals and debugging.
* Keep control-plane nodes in private subnets and use a bastion for SSH or use Session Manager.
* Consider automating the EC2 provisioning + kubeadm steps with Terraform + cloud-init once you’re happy with the manual flow.

---

If you want, I can:

* generate **complete ready-to-use cloud-init scripts** for control-plane and worker nodes (with your chosen pod CIDR),
* produce a **Terraform** template that provision EC2s + security groups + cloud-init to create the cluster,
* or provide the exact **kubeadm commands for a multi-control-plane HA** setup (including NLB configuration and etcd notes).

Tell me which of the three (cloud-init scripts, Terraform, multi-master HA commands) you’d like and I’ll produce it now.



✅ control-plane-bootstrap.sh
<!-- #!/bin/bash
set -euo pipefail

# Control Plane Setup (Ubuntu 20.04 / 22.04)

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd && systemctl enable containerd

modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet && systemctl start kubelet

echo "✅ Control Plane Bootstrap done on $(hostname) ($(hostname -I | awk '{print $1}'))" -->





🧱 worker-bootstrap.sh
<!-- #!/bin/bash
set -euo pipefail

# Worker Node Setup (Ubuntu 20.04 / 22.04)

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd && systemctl enable containerd

modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

systemctl enable kubelet && systemctl start kubelet

echo "✅ Worker Node Bootstrap done on $(hostname) ($(hostname -I | awk '{print $1}'))"
echo "ℹ️ Run the 'kubeadm join ...' command from your control plane to attach this node." -->