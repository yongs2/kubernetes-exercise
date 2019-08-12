# [Tools for Monitoring Resources](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)

## 1. momintoring

### 1) prometheus 정보

- k8s 의 자원 상태를 모니터링하는 용도로 cAdvisor, prometeus 등이 있음
- 그 중 prometeus 를 적용, [프로메테우스(kubernetes monitoring : phrometheus)](https://arisu1000.tistory.com/27857?category=787056)
- 프로메테우스 GitHub 저장소의 documentation/examples 을 보면, kubernetes 용 설정 파일을 [다운로드](https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml)
- 이 파일을 이용하여 config 를 생성할 것이며, 이후 prometheus-app.yaml 내의 설정 파일로 참조해야 하므로, 파일명을 변경
- 현재 최신 버전은 [v2.11.1](https://hub.docker.com/r/prom/prometheus/tags)

### 2) prometheus 설치

```sh
mv prometheus-kubernetes.yml prometheus-kubernetes-config.yaml
```

- 위 examples 에 있는 rbac-setup.yaml 파일을 가지고 권한 설정해야 하나, 오류로 데이터 수집이 안되어서, ClusterRoleBinding 항목에 serviceAccount 의 name을 default 으로 변경 후 생성

```sh
kubectl create configmap prometheus-kubernetes --from-file=./prometheus-kubernetes-config.yaml
kubectl create -f prometheus-rbac.yaml
kubectl create -f prometheus-app.yaml
```

- 서비스 및 pod 등이 제대로 생성되었는 지 확인

```sh
kubectl get deployment -l app=prometheus-app
kubectl get service -l app=prometheus-app
```

- 서비스 조회시 Port 정보를 확인한 후 웹으로 접속한다

```sh
curl http://192.168.0.80:30990/
```

### 3) prometheus 제거

```sh
kubectl delete -f prometheus-app.yaml
kubectl delete -f prometheus-rbac.yaml
kubectl delete configmap prometheus-kubernetes
```

## 2. [프로메테우스와 그라파나 연동](https://arisu1000.tistory.com/27857?category=787056)

### 1) grafana 생성

- 서비스 생성

```sh
kubectl create -f grafana.yaml
```

- 서비스 및 pod 등이 제대로 생성되었는 지 확인

```sh
kubectl get deployment -l k8s-app=grafana
kubectl get service -l kubernetes.io/name=grafana-app
```

- 서비스 조회시 Port 정보를 확인한 후 웹으로 접속한다

```sh
curl http://192.168.0.80:30300/
```

### 2) grafana 설정

- Add data source 를 선택
- 이름은 prometheus 로 지정하고, 타입은 Prometheus 로 지정
- HTTP URL은 <http://prometheus-app-svc.default.svc.k8s.local:9090> 로 설정
- Access 는 Server(default) 로 설정

### 3) [grafana 대쉬보드 설정](https://bcho.tistory.com/1270)

- Grafana 메뉴에서 아래와 같이 Create > Import 메뉴를 선택
- 대쉬보드 설정 JSON을 넣을 수 있는데, 또는 Grafana.com에 등록된 대쉬보드 템플릿 번호를 넣을 수도 있다
- 쿠버네티스 클러스터 모니터링 템플릿 ID 인 1621 을 입력
- 데이타 소스를 선택해줘야 하는데, 아래 그림과 같이 Prometheus 부분을 앞에서 만든 데이타 소스 이름인 prometheus 를 선택
