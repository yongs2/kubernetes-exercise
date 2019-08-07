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

## 4)  제거

```sh
kubectl delete pod mysql-client-loop --now
kubectl delete statefulset mysql
kubectl get pods -l app=mysql
kubectl delete configmap,service,pvc -l app=mysql
```
