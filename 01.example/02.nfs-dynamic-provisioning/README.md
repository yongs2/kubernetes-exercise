# Private cloud 에서 Dynamic Provisioning 

## kubernetes incubator 프로젝트 중 external-storage 중 [nfs-provisinor](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs) 를 사용, [참고](http://blog.naver.com/alice_k106/221360005336)

### PodSecurityPolicy 생성

```sh
kubectl create -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/psp.yaml
```

### ClusterRole, ClusterRoleBinding 생성

```sh
kubectl create -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/rbac.yaml
```

### nfs-provisioner 를 deployment

```sh
kubectl create -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/deployment.yaml
```

### example-nfs 인 storage-class 생성

```sh
kubectl create -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/class.yaml
```

### pvc 생성 후 pvc, pv 생성 확인

```sh
kubectl create -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/claim.yaml
kubectl get pv,pvc
```
