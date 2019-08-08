# [Fine Parallel Processing Using a Work Queue](https://kubernetes.io/docs/tasks/job/fine-parallel-processing-work-queue/)

## 1. redis 생성

```sh
kubectl create -f https://kubernetes.io/examples/application/job/redis/redis-service.yaml
kubectl create -f https://kubernetes.io/examples/application/job/redis/redis-pod.yaml
```

## 2. 테스트

### 1) Start a temporary interactive pod for running the Redis CLI

```sh
kubectl run -i --tty temp --image redis --command "/bin/sh"
```

- redis-cli 를 실행하여, redis에 접속

```sh
redis-cli -h redis
```

- 접속되면, 다음과 같이 명령어를 순서대로 호출하여 데이터 쓰기/읽기 테스트

```sh
rpush job2 "apple"
rpush job2 "banana"
rpush job2 "cherry"
rpush job2 "date"
rpush job2 "fig"
rpush job2 "grape"
rpush job2 "lemon"
rpush job2 "melon"
rpush job2 "orange"
```

- 데이터 추출 확인

```sh
lrange job2 0 -1
```

### 2) redis-client 로 mq 에 쌓인 message 을 읽는 worker 용 container 생성

```sh
docker build -t job-wq-2 .
docker tag job-wq-2 192.168.0.210:5000/job-wq-2
docker push 192.168.0.210:5000/job-wq-2
```

### 3. job 생성

```sh
kubectl apply -f ./job-wq2.yaml
kubectl describe jobs/job-wq-2
```

- redis queue 에서 데이터를 2개의 Pod 내의 worker.py 에서 데이터를 읽어서 로그로 출력
- jobs/job-wq-2 의 Job 에 포함된 Pod 2개의 로그를 확인

```sh
for pod in $(kubectl get pods --selector=job-name=job-wq-2 --output=jsonpath='{.items[*].metadata.name}') ;
do
echo ">>> kubectl logs ${pod}";
kubectl logs ${pod};
done
```

### 4. job 삭제

```sh
kubectl delete -f ./job-wq2.yaml
```

### 5. redis 삭제

```sh
kubectl delete -f https://kubernetes.io/examples/application/job/redis/redis-service.yaml
kubectl delete -f https://kubernetes.io/examples/application/job/redis/redis-pod.yaml
```
