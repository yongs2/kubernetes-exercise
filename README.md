# kubernetes-exercise

## k8s 설치

- [운영환경 - 컨테이너 런타임](https://kubernetes.io/ko/docs/setup/production-environment/container-runtimes/)
- [Calico 설치 문서](https://docs.projectcalico.org/v3.8/getting-started/kubernetes/installation/calico)
- [Docker, Kubernetes 환경에서 CUBRID 컨테이너 서비스 해보기](http://www.cubrid.com/blog/3820603)
- [Docker with Kubernetes #5 - Dashboard 설치](https://crystalcube.co.kr/199?category=834418)
- [dashboard 를 PortForwaring 으로 접속](https://github.com/freepsw/kubernetes_exercise)

## k8s 예제

- [kubernetes 문서 중 tasks 항목](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/)

## HPA 와 custom metric 관련 자료

- [scaling out](https://kubernetes.io/ko/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
- [기본적인 autoscaling 시험 방법](https://arisu1000.tistory.com/27858)
- 성능 관련 Metric 정보 확인 방법

```sh
kubectl get --raw "/apis/" | jq
kubectl get --raw "/apis/" | jq '.groups[].name'
kubectl get --raw "/apis/metrics.k8s.io/v1beta1"
```

- [Prometheus Adapter와 Opencensus를 이용한 Custom Metrics 수집 및 HPA 적용](https://m.blog.naver.com/alice_k106/221521978267)
- [HTTP load generator, ApacheBench](https://github.com/rakyll/hey)
- [Custom Metrics API](https://github.com/kubernetes/metrics/blob/master/IMPLEMENTATIONS.md)
- [An implementation of the custom.metrics.k8s.io API using Prometheus](https://github.com/directxman12/k8s-prometheus-adapter)
- [Deploying a custom metrics API Server and a sample app](https://github.com/luxas/kubeadm-workshop#deploying-a-custom-metrics-api-server-and-a-sample-app)
- [custom-metrics](https://github.com/luxas/kubeadm-workshop/tree/master/demos/monitoring)
- [Framework for implementing custom metrics support for Kubernetes](https://github.com/kubernetes-incubator/custom-metrics-apiserver)
- [Kubernetes HPA Autoscaling with Custom Metrics](https://icicimov.github.io/blog/kubernetes/Kubernetes_HPA_Autoscaling_with_Custom_Metrics/)

- custom-metrics 정보 확인 방법

```sh
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq '.resources[].name'
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/http_requests" | jq .
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/services/*/http_requests" | jq .
```
