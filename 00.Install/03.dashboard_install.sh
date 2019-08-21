#!/bin/bash

# Recommended setup <https://github.com/kubernetes/dashboard/wiki/Installation>
echo "=== Install dashboard"
mkdir -p ${HOME}/certs
kubectl create secret generic kubernetes-dashboard-certs --from-file=$HOME/certs -n kube-system
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

echo "=== check service"
kubectl get service -n kube-system

echo "=== create dashboard-sa"
kubectl create serviceaccount cluster-admin-dashboard-sa
kubectl create clusterrolebinding cluster-admin-dashboard-sa --clusterrole=cluster-admin --serviceaccount=default:cluster-admin-dashboard-sa

echo "=== get token"
kubectl get secret $(kubectl get serviceaccount cluster-admin-dashboard-sa -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

echo "=== check install"
kubectl -n kube-system get service kubernetes-dashboard
kubectl cluster-info

#end of script