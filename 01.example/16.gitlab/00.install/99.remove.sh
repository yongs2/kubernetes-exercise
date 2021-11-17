#!/bin/bash 

set -x

. ./00.profile

helm uninstall -n $KUBE_NAMESPACE $RELEASE_NAME

#kubectl delete ns $KUBE_NAMESPACE
