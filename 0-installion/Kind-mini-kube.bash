#!/bin/bash

# Debug mode 
set -exo 

# ------------------------------------------------------------
# Author      : Harshith
# GitHub      : https://github.com/harshith6322
# Gist        : https://gist.github.com/harshith6322
# ------------------------------------------------------------

<<kind_MiniKube
Kind (Kubernetes in Docker) use cases include local development for testing applications on a Kubernetes cluster, continuous integration (CI) for automated testing pipelines, and testing Kubernetes itself.
MiniKube is local Kubernetes, focusing on making it easy to learn and develop for Kubernetes.

Steps:
1. Get package manager name
2. Update & upgrade
3. Install dependencies (Docker) & start them
4. Install kind or minikube
5. Check version
kind_MiniKube

# Get user input
read -p "What is your package manager (apt or yum): " package_name
read -p "To install Kind type 'kind' or to install Minikube type 'kube': " kind_kube

# Variables
package=$package_name

# Update & upgrade
sudo $package update && sudo $package upgrade -y

# Install Docker dependency
if [ "$package" == "yum" ]; then
  sudo $package install -y docker 
  sudo systemctl enable docker
  sudo systemctl start docker
elif [ "$package" == "apt" ]; then
  sudo $package install -y docker.io 
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "❌ Incorrect package manager. Please enter yum or apt."
  exit 1
fi

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mkdir -p ~/.local/bin || sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
mv ./kubectl ~/.local/bin/kubectl 

# for ubuntu

# Install kind or minikube
if [ "$kind_kube" == "kind" ]; then
  [ "$(uname -m)" = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  kind --version 
elif [ "$kind_kube" == "kube" ]; then
  curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm -rf minikube-linux-amd64
  minikube version
else
  echo "❌ Incorrect input. Please enter kind or kube."
  exit 1
fi
