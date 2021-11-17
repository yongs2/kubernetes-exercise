#!/bin/bash 

set -x

. ./00.profile

#kubectl create ns $KUBE_NAMESPACE
helm install $RELEASE_NAME -n $KUBE_NAMESPACE $CHART_NAME $EXTRA_OPTION 
