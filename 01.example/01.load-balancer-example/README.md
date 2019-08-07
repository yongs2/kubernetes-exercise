
[외부 IP 주소를 노출하여 클러스터의 애플리케이션에 접속하기](https://kubernetes.io/ko/docs/tutorials/stateless-application/expose-external-ip-address/)

```
kubectl apply -f https://k8s.io/examples/service/load-balancer-example.yaml

kubectl get deployments hello-world
kubectl describe deployments hello-world
kubectl get replicasets
kubectl describe replicasets
kubectl expose deployment hello-world --type=LoadBalancer --name=my-service
kubectl get services my-service

[root@k8s-master ~]# kubectl get services --all-namespaces
NAMESPACE      NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
default        kubernetes             ClusterIP      10.96.0.1       <none>        443/TCP                  25h
default        my-service             LoadBalancer   10.111.223.36   <pending>     8080:32037/TCP           16s
kube-system    kube-dns               ClusterIP      10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP   25h
kube-system    kubernetes-dashboard   NodePort       10.106.6.56     <none>        443:30383/TCP            23h
my-namespace   node-hello-world       LoadBalancer   10.105.3.227    <pending>     3000:31089/TCP           132m
[root@k8s-master ~]# kubectl get services my-service
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
my-service   LoadBalancer   10.111.223.36   <pending>     8080:32037/TCP   20s
```

- 접속 : http://192.168.0.80:32037
