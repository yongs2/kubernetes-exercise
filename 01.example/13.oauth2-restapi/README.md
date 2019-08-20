# redis-oauth2-server 와 REST API 서버 연동

## 1. redis-oauth2-server 생성

### 1-1) service와 deployment 생성

```sh
kubectl apply -f ./redis-oauth2-server-deployment.yaml
```

### 1-2) 생성 확인

```sh
kubectl describe deployment redis-oauth2-server
kubectl get pods -l app=redis-oauth2-server
kubectl get rs -l app=redis-oauth2-server
kubectl get services -l app=redis-oauth2-server
```

### 1-3) 연동 포트 정보 확인

```sh
pod=$(kubectl get pods -l app=redis-oauth2-server --output=jsonpath='{.items[*].metadata.name}')
echo $pod
kubectl get pods ${pod} --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
```

### 1-4) 외부 접속

```sh
kubectl patch svc redis-oauth2-server -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.80"]}}'
```

## 2. REST API 서버 생성

### 2-1) service와 deployment 생성

```sh
kubectl apply -f ./ins-restapi-deployment.yaml
```

### 2-2) 생성 확인

```sh
kubectl describe deployment ins-restapi
kubectl get pods -l app=ins-restapi
kubectl get rs -l app=ins-restapi
kubectl get services -l app=ins-restapi
```

### 2-3) 연동 포트 정보 확인

```sh
pod=$(kubectl get pods -l app=ins-restapi --output=jsonpath='{.items[*].metadata.name}')
echo $pod
kubectl get pods ${pod} --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
```

### 2-4) 외부 접속

```sh
kubectl patch svc ins-restapi -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.80"]}}'
```
