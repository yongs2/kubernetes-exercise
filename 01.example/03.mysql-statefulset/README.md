# [mysql 를 replicated-stateful 서버로 생성](https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/)

## 1) configmap 생성 (master, slave 설정)

```sh
kubectl apply -f https://k8s.io/examples/application/mysql/mysql-configmap.yaml
```

## 2) 서비스 생성 (master(mysql), slave(mysql-read))

```sh
kubectl apply -f https://k8s.io/examples/application/mysql/mysql-services.yaml
```

## 3) Stateful-Set 생성

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/application/mysql/mysql-statefulset.yaml
```

- mysql-statfulset.yaml 에 storageClassName: "example-nfs" 추가

```sh
kubectl get pods -l app=mysql --watch
kubectl get pvc -l app=mysql
```

## 4) 시험

### 4-1) mysql-master (hostname 이 mysql-0.mysql) 에서 DB 생성

```sh
kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never --\
  mysql -h mysql-0.mysql <<EOF
CREATE DATABASE test;
CREATE TABLE test.messages (message VARCHAR(250));
INSERT INTO test.messages VALUES ('hello');
EOF
```

### 4-2) mysql-read 로 접속하여 DB 조회

```sh
kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never --\
  mysql -h mysql-read -e "SELECT * FROM test.messages"
```

### 4-3) mysql-read 로 데이터 조회시 접속된 서버 ID 출력

```sh
kubectl run mysql-client-loop --image=mysql:5.7 -i -t --rm --restart=Never --\
  bash -ic "while sleep 1; do mysql -h mysql-read -e 'SELECT @@server_id,NOW()'; done"
```

## 5) 제거

```sh
kubectl delete pod mysql-client-loop --now
kubectl delete statefulset mysql
kubectl get pods -l app=mysql
kubectl delete configmap,service,pvc -l app=mysql
```
