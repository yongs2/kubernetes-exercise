#!/bin/bash

# Check permission
if [ "$EUID" -ne 0 ]
  then echo "Please run as root (SUDO)"
  exit
fi

# Setting Environment
echo 1 > /proc/sys/net/ipv4/ip_forward

export API_ADDR="192.168.0.80" # Master 서버 외부 IP
export DNS_DOMAIN="k8s.local"
export POD_NET="172.16.0.0/16" # k8s 클러스터 POD Network CIDR

echo -e "=== kubeadm init ${POD_NET}"

# kubeadm init --pod-network-cidr 10.244.0.0/16
sudo kubeadm init --pod-network-cidr ${POD_NET} \
      --apiserver-advertise-address ${API_ADDR} \
      --service-dns-domain "${DNS_DOMAIN}"

sudo export KUBECONFIG=/etc/kubernetes/admin.conf

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo -e "=== calico init ${POD_NET}"
curl https://docs.projectcalico.org/v3.8/manifests/calico.yaml -O

sed -i -e "s?192.168.0.0/16?${POD_NET}?g" calico.yaml
kubectl apply -f calico.yaml
kubectl get pods --all-namespaces
