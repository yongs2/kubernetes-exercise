#!/bin/sh

set -x

. ./00.profile

kubectl -n $KUBE_NAMESPACE get secret ${RELEASE_NAME}-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode
