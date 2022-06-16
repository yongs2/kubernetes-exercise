#!/bin/sh

# remove cert-manager
kubectl delete namespace cert-manager
kubectl get crd | grep cert-manager | awk '{print $1}' | xargs kubectl delete crd
kubectl delete clusterissuer selfsigned-cluster-issuer

# remove certificate
kubectl delete certificate selfsigned-ca -n istio-system
