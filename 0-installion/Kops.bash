#!/bin/bash

#debug mode 
set -euo pipefail


# ------------------------------------------------------------
# Author      : Harshith
# GitHub      : https://github.com/harshith6322
# Gist        : https://gist.github.com/harshith6322
# ------------------------------------------------------------




<<Kops
What is kOps?
We like to think of it as kubectl for clusters.
kops will not only help you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes cluster, but it will also provision the necessary cloud infrastructure.
AWS (Amazon Web Services) and GCE (Google Cloud Platform) are currently officially supported, with DigitalOcean, Hetzner and OpenStack in beta support, and Azure in alpha.

step1 - getting name of package
step2 - update&upgrade
step3 - kubectl install
step4 - kops
step5 - steup
step6 - starting kops
Kops

exportss() {
    local user="$1"
    local s3="$2"

    if [ -n "$user" ]; then
        export NAME="${user}.k8s.aws"
        echo $NAME
    fi

    if [ -n "$s3" ]; then
        export KOPS_STATE_STORE="s3://${s3}"
        echo $KOPS_STATE_STORE
    fi
}


##reading inputs
read -p "what is your packages (apt | yum | dnf): "  package_name
read -p "S3  URL (s3://only_this_s3_name): " s3_url
read -p "Name of the user (harshith): " username


##dep
#update&&upgrade
sudo $package_name update && sudo $package_name -y upgrade 

#kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl
kubectl version || true

#kops
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops
sudo mv kops /usr/local/bin/kops
kops version || true

#export

exportss "$username" "$s3_url"

#kops starting
kops create cluster --name ${NAME} --zones=us-east-1a,us-east-1b --master-count=1 --master-size=c7i-flex.large --master-volume-size=30 --node-count=2 --node-size=t3.micro --node-volume-size=20 --image=ami-0360c520857e3138f
sleep 5s
kops update cluster --name ${NAME} --yes --admin

exportss "$username" "$s3_url"
















