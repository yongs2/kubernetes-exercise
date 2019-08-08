# [Connect a Front End to a Back End Using a Service](https://kubernetes.io/docs/tasks/access-application-cluster/connecting-frontend-backend/)

## 목표

- Deployment 를 이용하여 마이크로서비스를 생성하고, 실행
- frontend 를 이용하여 backend 로 트래픽을 연동
- frontend 와 backend 어플리케이션간 접속은 서비스를 사용

## 1. backend 생성

### 1-1) Deployment 를 이용하여 backend 생성

```sh
kubectl apply -f https://k8s.io/examples/service/access/hello.yaml
kubectl describe deployment hello
```

### 1-2) backend 서비스 생성

```sh
kubectl apply -f https://k8s.io/examples/service/access/hello-service.yaml
kubectl get svc hello
```

## 2. frontend 생성

### 2-1) Deployment, service, LoadBalancer 생성

```sh
kubectl apply -f https://k8s.io/examples/service/access/frontend.yaml
```

### 2-2) frontend 서비스 생성 확인

```sh
kubectl get service frontend
```

### 2-3) frontend Service 에 External-IP 설정

```sh
kubectl patch svc frontend -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.80"]}}'
```

## 3. frontend 를 통해 서비스 연동

### 3-1) 접속 확인

```sh
curl http://192.168.0.80/
```

### 3-2) frontend 로그 확인

```sh
for pod in $(kubectl get pods -l tier=frontend --output=jsonpath='{.items[*].metadata.name}') ;
do
echo ">>> kubectl logs ${pod}";
kubectl logs ${pod};
done
```

### 3-3) backend 로그 확인

```sh
for pod in $(kubectl get pods -l tier=backend --output=jsonpath='{.items[*].metadata.name}') ;
do
echo ">>> kubectl logs ${pod}";
kubectl logs ${pod};
done
```

## 4. 제거

### 4-1) frontend 제거

```sh
kubectl delete -f https://k8s.io/examples/service/access/frontend.yaml
```

### 4-2) backend 제거

```sh
kubectl delete -f https://k8s.io/examples/service/access/hello-service.yaml
kubectl delete -f https://k8s.io/examples/service/access/hello.yaml
```
