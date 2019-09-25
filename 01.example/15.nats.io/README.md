# nats.io 테스트

## [NATS cluster in kubernetes](https://github.com/nats-io/nats-operator)

```sh
kubectl apply -f https://github.com/nats-io/nats-operator/releases/latest/download/00-prereqs.yaml
kubectl apply -f https://github.com/nats-io/nats-operator/releases/latest/download/10-deployment.yaml
kubectl get crd | grep nats
```

- To create a NATS cluster, you must create a NatsCluster resource representing the desired status of the cluster. (3-node NATS cluster)

```sh
cat <<EOF | kubectl create -f -
apiVersion: nats.io/v1alpha2
kind: NatsCluster
metadata:
  name: example-nats-cluster
spec:
  size: 3
  version: "1.3.0"
EOF
kubectl get nats --all-namespaces
```

## NATS.io 클라이언트 테스트

- [nats.go 예제](https://github.com/nats-io/nats.go/)
