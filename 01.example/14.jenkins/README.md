# jenkins 설치

## 1. jenkins 서비스 및 deployment 설치

```sh
kubectl apply -f ./jenkins-deployment.yaml
kubectl patch svc jenkins -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.80"]}}'
pod=$(kubectl get pods -l app=jenkins --output=jsonpath='{.items[*].metadata.name}')
kubectl exec -it ${pod} /bin/bash
```
