#!/bin/sh

set -x

. ./00.profile

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io

export CERT_DIR=`pwd`/certs
mkdir -p ${CERT_DIR}


# self-signed certificate
# https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/
# subject 가 서로 다르게 설정해야 한다
ROOT_CERT_SUBJ="/O=exmple/CN=${INGRESS_DOMAIN}"
SERVER_SUBJ="/O=exmple-cicd/CN=*.${INGRESS_DOMAIN}"
if [ ! -f "${CERT_DIR}/ca.crt" ] ; then
  echo "subjectAltName=DNS:*.${INGRESS_DOMAIN}" > /tmp/altsubj.ext
  # root 인증서 생성, OUT (ca.key, ca.crt)
  openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj ${ROOT_CERT_SUBJ} -keyout ${CERT_DIR}/ca.key -out ${CERT_DIR}/ca.crt
  # root 인증서 CSR (인증 서명 요청) 생성, OUT (cert.csr, tls.key)
  openssl req -out ${CERT_DIR}/cert.csr -newkey rsa:2048 -nodes -keyout ${CERT_DIR}/tls.key -subj ${SERVER_SUBJ}
  # 사설 인증서 생성, OUT (tls.crt)
  openssl x509 -req -days 365 -extfile /tmp/altsubj.ext -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0 -in ${CERT_DIR}/cert.csr -out ${CERT_DIR}/tls.crt
fi

# gitlab-gw-cert
# https://istio.io/latest/docs/tasks/observability/gateways/
if [ -f "${CERT_DIR}/tls.crt" ] ; then
  kubectl delete -n istio-system secret gitlab-gw-cert ||
  kubectl create -n istio-system secret tls gitlab-gw-cert --key=${CERT_DIR}/tls.key --cert=${CERT_DIR}/tls.crt
fi

# gitlab-runner
# https://docs.gitlab.com/runner/install/kubernetes.html#providing-a-custom-certificate-for-accessing-gitlab
if [ -f "${CERT_DIR}/ca.crt" ] ; then
  kubectl get namespace $KUBE_NAMESPACE || kubectl create namespace $KUBE_NAMESPACE
  export SECRET_NAME=gitlab-runner-cert
  kubectl -n $KUBE_NAMESPACE delete secret ${SECRET_NAME} ||
  kubectl -n $KUBE_NAMESPACE create secret generic ${SECRET_NAME} --from-file=gitlab.${INGRESS_DOMAIN}.crt=${CERT_DIR}/ca.crt
fi
