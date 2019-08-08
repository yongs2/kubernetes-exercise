# [Coarse Parallel Processing Using a Work Queue](https://kubernetes.io/docs/tasks/job/coarse-parallel-processing-work-queue/)

## 1. Starting a message queue service (RabbitMQ)

### 1) rabbitmq 서비스 생성

```sh
kubectl create -f https://raw.githubusercontent.com/kubernetes/kubernetes/release-1.3/examples/celery-rabbitmq/rabbitmq-service.yaml
```

### 2) rabbitmq controller 생성, pod 는 1개 생성

```sh
kubectl create -f https://raw.githubusercontent.com/kubernetes/kubernetes/release-1.3/examples/celery-rabbitmq/rabbitmq-controller.yaml
```

## 2. Testing the message queue service

### 1) 임시 시험용 container 생성

  ```sh
  kubectl run -i --tty temp --image ubuntu:18.04
  ```

### 2) mq 시험을 위한 amqp-tools 설치

  ```sh
  cat /etc/os-release
  apt-get update
  apt-get install -y curl ca-certificates amqp-tools python dnsutils net-tools
  ifconfig -a
  nslookup rabbitmq-service
  env | grep RABBIT | grep HOST
  ```

### 3) foo queue 를 생성하여, hello 를 publish 하고, 이를 consume 하는 예제

  ```sh
  echo "rabbitmq-service is the hostname where the rabbitmq-service can be reached.  5672 is the standard port for rabbitmq."
  export BROKER_URL=amqp://guest:guest@rabbitmq-service:5672

  echo "Now create a queue:"
  /usr/bin/amqp-declare-queue --url=$BROKER_URL -q foo -d

  echo "Publish one message to it:"
  /usr/bin/amqp-publish --url=$BROKER_URL -r foo -p -b Hello

  echo "And get it back."
  /usr/bin/amqp-consume --url=$BROKER_URL -q foo -c 1 cat && echo
  ```

## 3. job1 큐를 이용한 예제

### 1) job1 queue 를 생성하고, 8개의 데이터를 publish 한다

  ```sh
  /usr/bin/amqp-declare-queue --url=$BROKER_URL -q job1  -d
  for f in apple banana cherry date fig grape lemon melon
  do
    /usr/bin/amqp-publish --url=$BROKER_URL -r job1 -p -b $f
  done
  ```

### 2) job1 queue에 데이터 정상적으로 적재되어 있는 지 확인

  ```sh
  /usr/bin/amqp-consume --url=$BROKER_URL -q job1 -c 1 cat && echo
  ```

### 3) job1 queue 를 cosume 하는 cronjob 를 생성, queue에 읽은 데이터를 출력할 container 를 먼저 생성

  ```sh
  cd job-wq;
  docker build -t job-wq .
  docker tag job-wq 192.168.0.210:5000/job-wq
  docker push 192.168.0.210:5000/job-wq
  ```

### 4) job_mq.yaml 를 시용하여 동시에 2개씩 총 8개의 pod 생성하도록 job 등록

  ```sh
  kubectl apply -f ./job_mq.yaml
  kubectl describe jobs/job-wq-1

  pods=$(kubectl get pods --selector=job-name=job-wq-1 --output=jsonpath='{.items[*].metadata.name}')
  echo $pods
  kubectl logs $pods
  ```

### 5) job-wa-1 이 생성되고, pod 가 2개씩 최대 8개까지 생성

### 6) job 삭제

  ```sh
  kubectl delete jobs/job-wq-1
  ```
