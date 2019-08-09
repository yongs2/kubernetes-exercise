# [동일 Pod 내의 container 들이 Shared Volume 을 공유하는 예제](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/)

- 동일 Pod 에서 동작하는 2개의 container 들이 volume 을 이용하여 통신하는 예제

## 1. 2개의 container 를 실행하는 1개의 pod 를 생성

### 1) 시나리오

- 1개의 pod 를 생성
- pod 내의 shared-data 이름의 volume 를 생성
- pod 내의 nginx-container 와 debian-container 를 생성
- nginx-container 는 volumeMounts 를 shared-data 를 /usr/share/nginx/html 디렉토리에 설정
- debian-container 는 volumeMounts 를 shared-data 를 /pod-data 디렉토리에 설정
- debian-container 는 기동시 /pod-data/index.html 에 echo Hello from the debian container 를 기록하고 종료

### 2) 생성 및 확인

```sh
kubectl apply -f https://k8s.io/examples/pods/two-container-pod.yaml
kubectl get pod two-containers --output=yaml
```

### 3) container 동작 확인

- nginx-container 로 접속

```sh
kubectl exec -it two-containers -c nginx-container -- /bin/bash
```

- nginx-container 에서 curl 로 index.html 확인

```sh
apt-get update
apt-get -y install curl procps
ps aux
curl localhost
cat /usr/share/nginx/html/index.html
```

### 4) 제거

```sh
kubectl delete -f https://k8s.io/examples/pods/two-container-pod.yaml
```
