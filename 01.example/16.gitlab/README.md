# k8s 에 gitlab 설치

## 1. gitlab

### 1.1 gitlab 설치

- gitlab 설치 관련 참고 자료
  - https://ruzickap.github.io/k8s-knative-gitlab-harbor/part-05/
  - https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/values-gke-minimum.yaml
  - https://faun.pub/deploy-gitlab-in-on-premises-kubernetes-1833ef599f80

### 1.2 istio 에 selfsigned certicate

- 참고 자료
  - https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/
  - https://istio.io/latest/docs/tasks/observability/gateways/

```sh
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io

CERT_DIR=/tmp/certs
mkdir -p ${CERT_DIR}
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj "/O=example Inc./CN=*.${INGRESS_DOMAIN}" -keyout ${CERT_DIR}/ca.key -out ${CERT_DIR}/ca.crt
openssl req -out ${CERT_DIR}/cert.csr -newkey rsa:2048 -nodes -keyout ${CERT_DIR}/tls.key -subj "/CN=*.${INGRESS_DOMAIN}/O=example organization"
openssl x509 -req -days 365 -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0 -in ${CERT_DIR}/cert.csr -out ${CERT_DIR}/tls.crt
kubectl create -n istio-system secret tls gitlab-gw-cert --key=${CERT_DIR}/tls.key --cert=${CERT_DIR}/tls.crt

# gitlab-wildcard-tls
kubectl create -n cicd secret tls gitlab-gw-cert --key=${CERT_DIR}/tls.key --cert=${CERT_DIR}/tls.crt

kubectl apply -f istio_config.yaml

kubectl -n cicd get gateway 
kubectl -n cicd get vs

# 설치 후 초기 root password 확인
kubectl -n cicd get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

## 2. gitlab runner

- 설치에 참고한 자료
  - https://docs.gitlab.com/runner/install/kubernetes.html
  - https://docs.gitlab.com/runner/install/kubernetes.html#providing-a-custom-certificate-for-accessing-gitlab
  - https://github.com/nirbhabbarat/gitlab-ephemeral-environment-demo

```sh
export CERT_DIR=/tmp/certs
export SECRET_NAME=gitlab-runner-secret

kubectl -n cicd get secret gitlab-wildcard-tls-ca -ojsonpath='{.data.cfssl_ca}' | base64 --decode > gitlab.${INGRESS_DOMAIN}.ca.pem

kubectl -n cicd delete secret ${SECRET_NAME}
kubectl -n cicd create secret generic ${SECRET_NAME} --from-file=gitlab.${INGRESS_DOMAIN}.crt=gitlab.${INGRESS_DOMAIN}.ca.pem

echo | openssl s_client -CAfile gitlab.${INGRESS_DOMAIN}.ca.pem  -connect gitlab.${INGRESS_DOMAIN}:443

helm -n cicd upgrade gitlab gitlab/gitlab -f override_values.yaml 
```

- 접속 후 확인

```sh
kubectl exec -n cicd  --stdin --tty $(kubectl get pods -n cicd | grep runner | awk '{print $1}') -- /bin/bash
df -h
gitlab-runner register # And follow the steps
```

- [다른 방법](https://stackoverflow.com/questions/66167590/self-hosted-gitlab-runner-register-failed-x509-certificate-signed-by-unknown-aut)

```sh
kubectl -n cicd get secret gitlab-wildcard-tls --template='{{ index .data "tls.crt" }}' | base64 --decode > gitlab.crt
kubectl -n cicd delete secret ${SECRET_NAME}
kubectl -n cicd create secret generic ${SECRET_NAME} --from-file=gitlab.${INGRESS_DOMAIN}.crt=gitlab.crt

echo | openssl s_client -CAfile gitlab.crt  -connect gitlab.${INGRESS_DOMAIN}:443
```

- [gitlab 사설 인증서 설명](https://github.com/gitlabhq/gitlab-runner/blob/master/docs/configuration/tls-self-signed.md)

- runner 에서 docker login 처리를 위한 configmap 생성 [참고](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27171)

```sh
kubectl -n cicd create configmap docker-daemon --from-file /etc/docker/daemon.json 
```

  - 참고 자료
    - https://workshop.infograb.io/gitlab-ci/33_add_docker_build_stage/2_add_build_stage/
    - https://do-hansung.tistory.com/75
    - https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/133
    - https://gitlab.com/gitlab-examples/kubernetes-example/-/blob/master/.gitlab-ci.yml

```sh
docker stop some-docker;docker rm some-docker
docker run --privileged -e DOCKER_TLS_CERTDIR="" --name some-docker -d docker:dind --insecure-registry=192.168.5.69:5000
docker exec -it some-docker /bin/sh
cat /usr/local/bin/docker-entrypoint.sh

mkdir -p /root/.docker
echo '{"auths":{"192.168.5.69:5000":{"auth":"YWRtaW46bnRlbHMxMjM0"}}}' > /root/.docker/config.json

docker login 192.168.5.69:5000

```

## 3. gitlab-ci 적용 예제

- sample-app/chart 참조
  - red/black deploy 을 위해서, 내부에서 Chart.yaml 의 appVersion 을 이용하여 각 sample-app 의 버전을 지정
  - sample-app 과 연동하는 sample-mod 의 버전을 별도로 관리하기 위해서 values.yaml 의 mod.version 으로 별도 관리
  - sample-mod 는 sample-app 의 binary 버전과도 연동이 필요하여, sample-app 의 버전과 sample-mod 의 버전을 동시에 관리
- 배포 절차
  - appVersion 이 변경되는 경우에는 sample-app 과 sample-mod 를 모두 변경
    - git 으로 chart.yaml 의 appVersion 을 변경한 후 commit 하면 pipeline 동작
    - 작업 순서
      - build-job : appVersion 에 해당하는 sample-app 을 기준으로 sample-mod 를 빌드
      - prepare-app : 현재 설치된 k8s 의 service 와 deployments 를 yaml로 추출, helm chart 을 기준으로 변경될 신규 버전용 yaml 추출
      - deploy-app : 신규 버전용 deployments yaml 을 k8s 에 적용
      - switch-new : 신규 버전용 service yaml 을 k8s 에 적용하여, 신규 deployments 로 전환
      - wait-new : 신규 버전 정상 작동 확인까지 시간 대기
      - remove-old : 기존 deployments 를 삭제
  - mod.version 이 변경되는 경우에는 sample-mod 만 변경
    - gitlab-ci 의 trigger 를 이용, curl 로 호출하면, trigger 에서 values.yaml 의 mod.version 을 변경한 후 commit 처리
    - 작업 순서
      - prepare-build : trigger 에서 요청한 mod.version 이 기존과 다른 신규 버전이면, values.yaml 의 mod.version 을 commit 처리
      - build-job : mod.version 에 해당하는 sample-app 을 기준으로 sample-mod 를 빌드
      - prepare-app : 현재 설치된 k8s 의 service 와 deployments 를 yaml로 추출, helm chart 을 기준으로 변경될 신규 버전용 yaml 추출
      - deploy-app : 신규 버전용 deployments yaml 을 k8s 에 적용
      - switch-new : 신규 버전용 service yaml 을 k8s 에 적용하여, 신규 deployments 로 전환
      - wait-new : 신규 버전 정상 작동 확인까지 시간 대기
      - remove-old : 기존 deployments 를 삭제
