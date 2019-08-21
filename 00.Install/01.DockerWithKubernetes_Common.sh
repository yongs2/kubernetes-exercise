#!/bin/bash

USER=rnd	# rnd

set -x

RED='\033[0;31m'
NC='\033[0m'

# Check permission
if [ "$EUID" -ne 0 ]
  then echo -e "${RED}Please run as root (SUDO)${NC}"
  exit
fi

# update yum
echo -e "${RED}UPDATE YUM${NC}"
sudo yum update -y

# Stop Firewalld
echo -e "${RED}TURN OFF FIREWALLD${NC}"
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# uninstall old version docker
echo -e "${RED}REMOVING OLD VERSION DOCKER${NC}"
sudo yum remove -y docker \
docker-client \
docker-client-latest \
docker-common \
docker-latest \
docker-latest-logrotate \
docker-logrotate \
docker-selinux \
docker-engine-selinux \
docker-engine

# SETUP THE REPOSITORY
## Install Required Packages
echo -e "${RED}INSTALL REQUIRED PACKAGES${NC}"
sudo yum install -y yum-utils \
device-mapper-persistent-data \
lvm2

## Setup Repository
echo -e "${RED}SETUP REPOSITORY${NC}"
sudo yum-config-manager \
--add-repo \
https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
echo -e "${RED}INSTALL DOCKER${NC}"
sudo yum install -y docker-ce

# private registry
sudo bash -c 'cat <<EOF > /etc/docker/daemon.json
{
    "insecure-registries": ["192.168.0.210:5000"]
}
EOF'

# Start Docker
echo -e "${RED}START DOCKER${NC}"
sudo systemctl start docker
sudo systemctl enable docker

# Add User To Docker Group
echo -e "${RED}ADD CURRENT USER INTO DOCKER GROUP${NC}"
sudo /sbin/usermod -aG docker $USER

# INSTALL KUBERNETES
echo -e "${RED}INSTALL KUBERNETES${NC}"
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF'

# Disable Security Linux
echo -e "${RED}TURN OFF SELINUX${NC}"
sudo /sbin/setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo /usr/sbin/sestatus

# Disable SWAP
echo -e "${RED}DISABLE SWAP${NC}"
sudo /sbin/swapoff -a
sed s/\\/dev\\/mapper\\/centos-swap/#\ \\/dev\\/mapper\\/centos-swap/g -i /etc/fstab

# Set IP Forward
echo -e "${RED}SET IP FORWARDING${NC}"
echo -e 1 > sudo /proc/sys/net/ipv4/ip_forward

# Network Setting
echo -e "${RED}SET NETWORK CONFIGURATION${NC}"
sudo bash -c 'cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'
sudo sysctl --system

# Install Kubernetes
echo -e "${RED}INSTALL KUBERNETES${NC}"
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Start kubelet
echo -e "${RED}START KUBELET${NC}"
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet
