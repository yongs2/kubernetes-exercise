# [Example: Deploying WordPress and MySQL with Persistent Volumes](https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/)

## mysql 과 wordpress 생성, kustomization 사용

```sh
mkdir -p mysql-wordpress-persistent-volume; cd mysql-wordpress-persistent-volume/
wget https://kubernetes.io/examples/application/wordpress/mysql-deployment.yaml
wget https://kubernetes.io/examples/application/wordpress/wordpress-deployment.yaml
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: mysql-pass
  literals:
  - password=YOUR_PASSWORD
EOF
cat <<EOF >>./kustomization.yaml
resources:
  - mysql-deployment.yaml
  - wordpress-deployment.yaml
EOF
kubectl apply -k ./
kubectl get pvc
kubectl get pods
kubectl get services wordpress
```

## 서비스에 Externel-IP 설정

```sh
kubectl patch svc wordpress -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.81"]}}'
```

## Cleanup

```sh
kubectl delete -k ./
```
