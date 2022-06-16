#!/bin/bash

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | sed 's/\./-/g')
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
export GITLAB_DOMAIN="gitlab.${INGRESS_DOMAIN}"

get_secret_value() {
  KUBE_NAMESPACE=$1
  SECRET_NAME=$2
  DATA_KEY=$(echo "${3}" | sed 's/\./\\\./g')
  
  # echo ">> get_secret_value, 1[${KUBE_NAMESPACE}], 2[${SECRET_NAME}], 3[${DATA_KEY}]"
  retval=$(kubectl -n ${KUBE_NAMESPACE} get secret ${SECRET_NAME} -ojsonpath='{.data.'${DATA_KEY}'}')
  # echo "<< get_secret_value.ret[${retval}]"
}

get_cert_dates() {
  KUBE_NAMESPACE=$1
  SECRET_NAME=$2
  CRT_NAME=$3

  # echo ">> get_cert_dates, 1[${KUBE_NAMESPACE}], 2[${SECRET_NAME}], 3[${CRT_NAME}]"
  get_secret_value ${KUBE_NAMESPACE} ${SECRET_NAME} ${CRT_NAME}
  CERT_BASE64=$retval

  retval=$(openssl x509 -in <(echo "${CERT_BASE64}" | base64 -d) -noout -dates | tr '\n' ' ')
  # echo "<< get_cert_dates.ret[${retval}]"
}

# get ROOT_CA of istio-system/selfsigned-ca-tls
export NS_ROOT_CA="istio-system"
export SECRET_ROOT_CA="selfsigned-ca-tls"
export CRT_ROOT_CA="ca.crt"
get_cert_dates ${NS_ROOT_CA} ${SECRET_ROOT_CA} ${CRT_ROOT_CA}
DATES_ROOT_CA=$retval
echo "DATES_ROOT_CA   =[${DATES_ROOT_CA}]"

# get GITLAB_TLS of cicd/selfsigned-cert-domain
export NS_GITLAB_TLS="cicd"
export SECRET_GITLAB_TLS="selfsigned-cert-domain"
export CRT_GITLAB_TLS="${GITLAB_DOMAIN}.crt"
get_cert_dates ${NS_GITLAB_TLS} ${SECRET_GITLAB_TLS} ${CRT_GITLAB_TLS}
DATES_GITLAB_TLS=$retval
echo "DATES_GITLAB_TLS=[${DATES_GITLAB_TLS}]"

if [ "$DATES_ROOT_CA" = "$DATES_GITLAB_TLS" ] ; then 
  echo "SAME"
else
  echo "DIFF"
  # Update GITLAB_TLS of cicd/selfsigned-cert-domain with ROOT_CA of istio-system/selfsigned-ca-tls
  get_secret_value ${NS_ROOT_CA} ${SECRET_ROOT_CA} ${CRT_ROOT_CA}
  CERT_BASE64=$retval
  kubectl -n ${NS_GITLAB_TLS} patch secret ${SECRET_GITLAB_TLS} -p "{\"data\":{\"${CRT_GITLAB_TLS}\":\"${CERT_BASE64}\"}}"
fi
