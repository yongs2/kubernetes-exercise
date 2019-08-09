# [Log Collector Examples](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/)

## 1. Use fluentd to collect and distribute audit events from log file

### 1-1) [ElasticSearch로 수집해서 모아보기](https://arisu1000.tistory.com/27852)

- 로그 수집기에서 수집된 로그를 받아줄 [elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)
- 노드 1대에서만 실행되는 형태로 구성, 최신 버전은 7.3.0

```sh
kubectl create -f elasticsearch.yaml
kubectl describe deployments elasticsearch
kubectl get services elasticsearch
kubectl get deployment -l app=elasticsearch
kubectl get rs -l app=elasticsearch
kubectl get pods -l app=elasticsearch
```

- 동작 확인

```sh
kubectl get service elasticsearch-svc
curl http://192.168.0.80:30920/
ping elasticsearch-svc

pods=$(kubectl get pods -l app=elasticsearch --output=jsonpath='{.items[*].metadata.name}')
echo $pods
kubectl exec -it $pods -- /bin/bash

curl http://192.168.0.80:30920/_cluster/state?pretty
```

### 1-2) [UI인 kibana를 함께 사용해서 데이터 검색을 편하게 사용](https://arisu1000.tistory.com/27852)

- [kibana](https://www.elastic.co/guide/en/kibana/current/docker.html) 최신 버전은 7.3.0
- kibana 환경 설정은 <https://www.elastic.co/guide/en/kibana/current/docker.html> 참조
- kibana dockerfile 은 <https://github.com/elastic/dockerfiles/tree/v7.3.0/kibana> 를 참조
- kibana pod 의 log에서 <http://elasticsearch:9200> 으로 만 기록하고 있으면서, <http://192.168.0.80:30561> 으로 접근시 Kibana server is not ready yet 으로 출력하고 있다면, ELASTICSEARCH_HOSTS 환경 변수를 추가로 설정해야 함

```sh
kubectl create -f kibana.yaml
kubectl describe deployments kibana
ping kibana-svc
```

- 동작 확인

```sh
kubectl get service kibana-svc
curl http://192.168.0.80:30561/

pods=$(kubectl get pods -l app=kibana --output=jsonpath='{.items[*].metadata.name}')
echo $pods
kubectl exec -it $pods -- /bin/bash
```

### 1-3) [fluentd를 이용해서 로그 수집하기](https://arisu1000.tistory.com/27852)

- fluentd를 이용해서 elasticsearch에 쿠버네티스에서 발생한 로그를 저장
- fluentd 의 쿠버네티스용으로 만들어진 다양한 dockerfile들이 있고 쿠버네티스 배포용 yaml파일들이 [github](https://github.com/fluent/fluentd-kubernetes-daemonset) 에 있음
- 로그를 수집해서 다양한 외부 저장소로 보낼 수 있도록 되어 있지만 elasticsearch용 배포 파일인 [fluentd-daemonset-elasticsearch-rbac.yaml](https://github.com/fluent/fluentd-kubernetes-daemonset/blob/master/fluentd-daemonset-elasticsearch-rbac.yaml) 내용을 조금 수정
- Daemonset 으로 구성된 이유는 여러대의 노드로 구성된 클러스터에서 로그 수집기는 모든 노드에서 실행되어서 로그를 수집해야 합니다.
- 노드에서 실제 로그가 쌓이는 위치인 /var/log와 /var/lib/docker/containers를 볼륨으로 마운트

```sh
kubectl create -f fluentd-daemonset-elasticsearch-rbac.yaml
kubectl get pods -l k8s-app=fluentd-logging -n kube-system
```

- 동작 확인

```sh
kubectl get pods -l k8s-app=fluentd-logging -n kube-system --output=jsonpath='{.items[*].metadata.name}'
```

## 2. kibana 에서 로그 조회

### 1) Management 로 이동

- Elastich 항목에 있는 Index management 을 선택
- logstash-* 로 항목이 생성되어 있는 것을 확인

### 2) kibana 항목에 있는 Index Patterns 으로 이동

- logstash-* 으로 신규 생성

### 3) 좌측 메뉴의 Discover 로 이동

- Filter 를 * 로 선택
- 조회 날짜를 선택한 후 Refresh 버튼 선택
