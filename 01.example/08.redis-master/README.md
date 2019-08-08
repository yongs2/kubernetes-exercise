# [Creating Redis deployment and service](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

## 1. redis-master deployment 생성

### 1-1) 생성

```sh
kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-deployment.yaml
```

- 기존은 redis 버전이 낮아서, 최신 버전으로 변경
- hub.docker 에 있는 이미지를 쓰기 위해서 image: k8s.gcr.io/redis:e2e 를 image: docker.io/redis:5.0 로 변경

### 1-2) 생성 확인

```sh
kubectl get pods
kubectl get deployment
kubectl get rs
```

## 2. redis-master 서비스 생성

### 2-1) 생성

```sh
kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-service.yaml
```

### 2-2) 생성 확인

```sh
kubectl get svc | grep redis
```

### 2-3) redis 대기 포트 정보 확인

```sh
pod=$(kubectl get pods -l app=redis --output=jsonpath='{.items[*].metadata.name}')
echo $pod
kubectl get pods ${pod} --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
```

## 3. 외부 접속

```sh
kubectl patch svc redis-master -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.80"]}}'
```
