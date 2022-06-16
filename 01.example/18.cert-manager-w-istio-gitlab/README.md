# cert-manager 를 이용한 self-signed cert 사용 및 istio 연동, gitlab 적용

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

- clusterissuer 을 이용하여 isCA 가 true 인 사설 인증서를 생성
  - gitlab 의 runner 실행시 ssl 접근시 사용할 ca 로 사용
- Issuer 를 추가로 istio-system 에 생성
- Issuer 를 이용하여 isCA 가 false 인 사설 인증서를 생성
  - istio 의 gitlab-gateway 를 생성하여 server tls 인증서로 사용

```sh
kubectl apply -f 03.selfsigned-cert.yaml
```

## 2. istio 연동

### 2.1 istio 의 ingress 설정

- clusterissuer 에서 생성한 ca 인증서를 이용하여 gitlab-runner 에서 사용할 secret 생성 (17.override_values.yaml)
- selfsigned-ca-issuer 에서 생성한 server tls 인증서를 이용하여 gitlab-gateway 설정 (16.istio-ingress-gitlab.yaml)

```sh
./11.install_cert_gitlab.sh
```

## 3. cert-manager 에서 갱신한 인증서 반영

### 3.1 cronjob

- 03.selfsigned-cert.yaml 에서 지정한 시간 안에 cert-manager 에서 self-signed 인증서를 갱신
- 갱신되는 인증서는 isitio-system 에 있는 selfsigned-ca-tls, selfsigned-server-tls
- 이때 생성되는 secret 내의 key 는 ca.crt, tls.crt 등으로 정의됨
- gitlab-runner 에서 사용하는 secret 는 gitlab.192-168-5-81.nip.io.crt 로 key 를 사용해야 함
- 주기적으로 비교해서 selfsigned-ca-tls 가 변경되면, cicd/selfsigned-cert-domain 을 갱신해야 함

```sh
./19.update_runner_cert.sh
```

- 이러한 절차를 자동으로 하기 위해서 k8s cronjob 으로 등록
- cronjob 실행시 kubectl 명령 수행을 위해서 ClusterRoleBinding 과 ServiceAccount 를 생성해야 함

```sh
kubectl apply -f 18.cronjob_update_runner_cert.yaml
```
