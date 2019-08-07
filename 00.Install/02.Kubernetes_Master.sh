#!/bin/bash

# Check permission
if [ "$EUID" -ne 0 ]
  then echo "Please run as root (SUDO)"
  exit
fi

# Setting Environment
sudo echo 1 > /proc/sys/net/ipv4/ip_forward

# kubeadm init --pod-network-cidr 10.244.0.0/16
sudo kubeadm init --pod-network-cidr 192.168.0.0/16
sudo export KUBECONFIG=/etc/kubernetes/admin.conf


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
kubectl get pods --all-namespaces
