# cert-manager 를 이용한 self-signed cert 사용 및 istio 연동

## 1. cert-manager 설치

### 1.1 cert-manager 최신 버전 설치

```sh
./01.install-cert-manager.sh
```

### 1.2 selfsigned-cluster-issuer 생성

```sh
kubectl apply -f 02.selfsigned-cluster-issuer.yaml
```

### 1.3 Certificate 생성 (self-signed)

```sh
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | sed 's/\./-/g')
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io

kubectl apply -f 03.selfsigned-cert.yaml

kubectl -n istio-system get cert -o wide
kubectl describe clusterissuer selfsigned-cluster-issuer
```

## 2. istio 연동

### 2.1 테스트용 nginx web server 설치

```sh
kubectl -n default apply -f 04.nginx-web.yaml
```

### 2.2 istio 의 ingress 설정

```sh
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | sed 's/\./-/g')
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io

kubectl apply -f 05.istio-ingress-web.yaml

curl -v http://www.${INGRESS_DOMAIN}
curl -vk https://www.${INGRESS_DOMAIN}
```

## 참고

- [istio 가 ingress 로 사용하고 있다면, istio-system 에 cert 를 생성](https://medium.com/@rd.petrusek/kubernetes-istio-cert-manager-and-lets-encrypt-c3e0822a3aaf)
