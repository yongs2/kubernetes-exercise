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

### 1-5) 초기 데이터 설정

- pod 로 접속

```sh
pod=$(kubectl get pods -l app=redis-oauth2-server --output=jsonpath='{.items[*].metadata.name}')
kubectl exec -it ${pod} /bin/bash
```

- 초기 client 정보 설정

```sh
cd /app/model
node redisTestData.js
node redisTestQuery.js
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

## 3. log 수집에 추가

### 3-1) [fluent-bit 사용](https://yunsangjun.github.io/blog/kubernetes/2018/07/06/kubernetes-logging.html)

```sh
kubectl create -f ./fluentbit-sidecar-config.yaml
```

### 3-2) 수정된 ins-restapi 적용, container 가 2개 (ins-restapi, fluent-bit)

- ins-restapi 에서 log-volume 를 /app/log 에 mount
- fluent-bit 에서는 log-voulume 를 /var/logs 에 mount
- fluentbit-sidecar-config 에서 fluent-bit.conf 를 참조하면, /var/logs/app.log 을 지정

```sh
pod=$(kubectl get pods -l app=ins-restapi --output=jsonpath='{.items[*].metadata.name}')
kubectl exec -it $pod -c ins-restapi /bin/bash
kubectl logs $pod -c fluent-bit
```

### 3-3) 기동 후 kibana 에 index pattern 설정

- Kibana 접속 > 왼쪽 메뉴 > Management 메뉴 선택 > Kibana > Index Patterns 선택 하고 fluentbit 를 입력
- 왼쪽 메뉴 > Discover 메뉴 선택 > select 박스에서 fluentbit 를 선택
- 로그 검색되는 지 확인
