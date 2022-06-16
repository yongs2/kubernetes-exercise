#!/bin/sh

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | sed 's/\./-/g')
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
export KUBE_NAMESPACE=cicd
export RELEASE_NAME=gitlab
export CHART_NAME=gitlab/gitlab

CUR_DIR=$PWD
ORG_GITLAB_DIR="$PWD/16.gitlab"

uninstall_cert_gitlab() {
    helm uninstall -n ${KUBE_NAMESPACE} $RELEASE_NAME
}

remove_cur_istio_config() {
    cd ${ORG_GITLAB_DIR}
    CUR_DOMAIN_CNT=`kubectl get gateway -n cicd -o yaml | grep "gitlab\.192\.168\.5\.81\.nip\.io" | wc -l`
    echo "CUR_DOMAIN_CNT=${CUR_DOMAIN_CNT}, pwd=${PWD}"
    if [ $CUR_DOMAIN_CNT -ge 1 ] ; then
        kubectl delete -f istio_config.yaml
    fi
    cd ${CUR_DIR}
}

update_cur_selfsigned_cert() {
    echo "update_cur_selfsigned_cert, pwd=${PWD}"

    # selfsigned-cert-domain for gitlab-runner
    kubectl -n $KUBE_NAMESPACE delete secret selfsigned-cert-domain
    kubectl get secret selfsigned-ca-tls --namespace=istio-system -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/ca.crt
    kubectl -n $KUBE_NAMESPACE create secret generic selfsigned-cert-domain --from-file=gitlab.${INGRESS_DOMAIN}.crt=/tmp/ca.crt 
}

install_cert_gitlab() {
    echo "install_cert_gitlab, pwd=${PWD}"
    kubectl apply -f 16.istio-ingress-gitlab.yaml
    # helm -n ${KUBE_NAMESPACE} list
    helm -n ${KUBE_NAMESPACE} history ${RELEASE_NAME}
    helm -n ${KUBE_NAMESPACE} template ${RELEASE_NAME} ${CHART_NAME}
    helm -n ${KUBE_NAMESPACE} get values ${RELEASE_NAME}
    helm upgrade --install ${RELEASE_NAME} ${CHART_NAME} -n ${KUBE_NAMESPACE} -f 17.override_values.yaml
}

# uninstall_cert_gitlab
# sleep 20
remove_cur_istio_config
update_cur_selfsigned_cert
install_cert_gitlab
# curl -vk https://gitlab.192-168-5-81.nip.io
