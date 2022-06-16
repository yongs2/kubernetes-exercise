#!/bin/sh

VERSION=`curl -s https://api.github.com/repos/cert-manager/cert-manager/releases/latest | grep tag_name | cut -d '"' -f 4`
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${VERSION}/cert-manager.yaml
kubectl -n cert-manager get all
