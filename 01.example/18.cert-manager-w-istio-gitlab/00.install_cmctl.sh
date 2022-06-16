#!/bin/sh

OS=`uname | tr A-Z a-z`
ARCH=`uname -m | sed -E 's/^(aarch64|aarch64_be|armv6l|armv7l|armv8b|armv8l)$$/arm64/g' | sed -E 's/^x86_64$$/amd64/g'`

get_version_cert-manager() {
    export VERSION=`curl -s https://api.github.com/repos/cert-manager/cert-manager/releases/latest | grep tag_name | cut -d '"' -f 4`
}

# install cert-manager
install_cert-manager() {
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${VERSION}/cert-manager.yaml
}

# install cmctl
install_cmctl() {
    BINARY=cmctl
    BINARY_NAME=${BINARY}-${OS}-${ARCH}
    DOWNLOAD_FILE=${BINARY_NAME}.tar.gz
    /usr/bin/curl -L https://github.com/cert-manager/cert-manager/releases/download/${VERSION}/${DOWNLOAD_FILE} -o /tmp/${DOWNLOAD_FILE}
    tar -zxvf /tmp/${DOWNLOAD_FILE} -C /usr/local/bin
}

get_version_cert-manager
#install_cert-manager
install_cmctl
