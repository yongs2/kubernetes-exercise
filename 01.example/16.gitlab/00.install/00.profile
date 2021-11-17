#!/usr/bin/env

KUBE_NAMESPACE=cicd
RELEASE_NAME=gitlab
CHART_NAME=gitlab/gitlab
EXTRA_OPTION="
	-f override_values.yaml
"
STORAGE_CLASS=openebs-hostpath

INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
