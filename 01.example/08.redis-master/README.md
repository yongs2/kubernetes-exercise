# [Creating Redis deployment and service](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

## 1. redis-master 생성

### 1-1) deployment 생성

```sh
kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-deployment.yaml
```

- 기존은 redis 버전이 낮아서, 최신 버전으로 변경
- hub.docker 에 있는 이미지를 쓰기 위해서 image: k8s.gcr.io/redis:e2e 를 image: docker.io/redis:5.0 로 변경

### 1-2) deployment 생성 확인

```sh
kubectl get pods -l app=redis
kubectl get deployment -l app=redis
kubectl get rs -l app=redis
```

### 1-3) redis-master 서비스 생성

```sh
kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-service.yaml
```

### 1-4) 서비스 생성 확인

```sh
kubectl get services -l app=redis
```

### 1-5) redis 대기 포트 정보 확인

```sh
pod=$(kubectl get pods -l app=redis --output=jsonpath='{.items[*].metadata.name}')
echo $pod
kubectl get pods ${pod} --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
```

### 1-6) 외부 접속

```sh
kubectl patch svc redis-master -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.80"]}}'
```

## 2. redis slave 실행

### 2-1) deployment 생성

```sh
kubectl apply -f https://k8s.io/examples/application/guestbook/redis-slave-deployment.yaml
```

- 기존은 redis 버전이 낮아서, 최신 버전으로 변경
- hub.docker 에 있는 이미지를 쓰기 위해서 image: k8s.gcr.io/redis:e2e 를 image: docker.io/redis:5.0 로 변경

### 2-2) deployment 생성 확인

```sh
kubectl get pods -l app=redis
kubectl get deployment -l app=redis
kubectl get rs -l app=redis
```

### 2-3) 서비스 생성

```sh
kubectl apply -f https://k8s.io/examples/application/guestbook/redis-slave-service.yaml
```

### 2-4) 서비스 생성 확인

```sh
kubectl get services -l app=redis
```

## 3. 제거

```sh
kubectl delete -f ./redis-master-deployment.yaml
kubectl delete -f ./redis-master-service.yaml
kubectl delete -f ./redis-slave-deployment.yaml
kubectl delete -f ./redis-slave-service.yaml
```

## 4. redis-statefulset 구성 예제

[Deploying Redis Cluster with StatefulSets](https://schoolofdevops.github.io/ultimate-kubernetes-bootcamp/13_redis_statefulset/)
