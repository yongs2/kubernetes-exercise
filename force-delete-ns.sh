#!/bin/bash
#
# refer to 
#   https://nasermirzaei89.net/2019/01/27/delete-namespace-stuck-at-terminating-state/
#   https://hyunsoft.tistory.com/170

if [ $# -ne 1 ]; then
  echo "script need 1 parameter"
  echo "ex) ./force-delete-ns.sh kubeflow"
  exit 1
fi

IS_RUN_PROXY=`netstat -na | grep 8001 | wc -l`
echo "IS_RUN_PROXY=${IS_RUN_PROXY}"
if [ $IS_RUN_PROXY -ne 1 ] ; then
    echo "Running proxy"
    kubectl proxy &
fi

kubectl get ns
kubectl get ns $1 -o json > delete-ns.json
sed -i 's/"kubernetes"//g' delete-ns.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @delete-ns.json http://127.0.0.1:8001/api/v1/namespaces/$1/finalize
kubectl get ns
