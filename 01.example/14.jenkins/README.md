# jenkins 설치

## 1. [jenkins-leader 서비스 및 deployment 설치](https://bryan.wiki/295)

### 1) namespace, [권한](https://github.com/jenkinsci/kubernetes-plugin/blob/master/src/main/kubernetes/service-account.yml) 및 생성

```sh
kubectl create namespace ns-jenkins
kubectl apply -f ./jenkins-sa-clusteradmin-rbac.yaml -n ns-jenkins
kubectl apply -f ./jenkins-deployment.yaml -n ns-jenkins

kubectl get svc -n ns-jenkins
kubectl get pods -n ns-jenkins

kubectl patch svc jenkins-leader-svc -n ns-jenkins -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.0.80"]}}'
```

### 2) 설치 확인

- 로그 확인

```sh
pod=$(kubectl get pods -n ns-jenkins -l app=jenkins-leader --output=jsonpath='{.items[*].metadata.name}')
kubectl logs -n ns-jenkins -f ${pod}
```

- jenkins 설치용 임시 암호 확인

```sh
kubectl exec -it -n ns-jenkins ${pod} -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### 3) jenkins 설정

- jenkins-leader 서비스의 NodePort 를 확인하여 <http://192.168.0.80:30500> 으로 접속
- 설치용 임시 암호로 로그인 후 기본 플러그인 설치
- 추가로 Cloud Providers 항목의 kubenertes 플러그인 설치
- jenkins 관리 메뉴에서 configuration system(시스템 설정)에서 하단의 cloud 항목으로 이동하여 Add a new cloud 를 선택하고 kubernetes 를 선택
  - Name : kubenrnetes
  - Kubernetes URL : <https://kubernetes.default.svc.k8s.local:443> ([443 포트를 설정하는 이유](https://issues.jenkins-ci.org/browse/JENKINS-59000))
  - Disable https certificate check : check
  - Kubernetes Namespace : ns-jenkins 로 설정
  - Credentials : Add 를 선택한 후 Domain : Global credentias 선택, Kind : Kubernetes Service Account 선택
  - Jenkins URL : <http://jenkins-leader-svc.ns-jenkins.svc.k8s.local>
  - Jenkins tunnel : jenkins-leader-svc.ns-jenkins.svc.k8s.local:50000

### 4) 빌드 테스트

- 메인 화면에서 New Item을 선택하고 item 이름을 입력한 후 pipeline 으로 선택
- Pipeline script 에 다음을 입력

```Script
podTemplate(label: 'pod-golang',
  containers: [
    containerTemplate(
      name: 'golang',
      image: 'golang',
      ttyEnabled: true,
      command: 'cat'
    )
  ]
) {
  node ('pod-golang') {
    stage 'Switch to Utility Container'
    container('golang') {
      sh ("go version")
    }
  }
}
```

- Build Now 을 선택하고, console output 을 확인
- ns-jenkins 내에서 하위 pod 가 생성되는 지 확인

- container 접속 후 token 정보 확인

```sh
kubectl get pods -n ns-jenkins -w
```

참고 사이트 : <https://futurecreator.github.io/2019/01/19/spring-boot-containerization-and-ci-cd-to-kubernetes-cluster/>

## 2. 제거

```sh
kubectl delete -f ./jenkins-deployment.yaml -n ns-jenkins
kubectl delete -f ./jenkins-sa-clusteradmin-rbac.yaml -n ns-jenkins
```

## 3. [jenkins custom docker images 생성](https://bryan.wiki/295)

```sh
export ADMIN_USR=${USERID}; export ADMIN_PWD=${PASSWORD}; export DOCKER_REGISTRY=192.168.0.210:5000

export NAMESPACE=ns-jenkins
export JENKINS_POD=$(kubectl get pods -n $NAMESPACE | grep jenkins-leader | awk '{print $1}')

export DEST_PATH=docker/jenkins-kubernetes-leader

mkdir -p ${DEST_PATH}
kubectl cp ${NAMESPACE}/${JENKINS_POD}:var/jenkins_home/config.xml ${DEST_PATH}/config.xml
kubectl cp ${NAMESPACE}/${JENKINS_POD}:var/jenkins_home/users/ ${DEST_PATH}/users/
kubectl cp ${NAMESPACE}/${JENKINS_POD}:var/jenkins_home/jobs/ ${DEST_PATH}/jobs/
kubectl cp ${NAMESPACE}/${JENKINS_POD}:var/jenkins_home/secrets/master.key ${DEST_PATH}/secrets/master.key
kubectl cp ${NAMESPACE}/${JENKINS_POD}:var/jenkins_home/secrets/hudson.util.Secret ${DEST_PATH}/secrets/hudson.util.Secret
kubectl cp ${NAMESPACE}/${JENKINS_POD}:var/jenkins_home/secrets/slave-to-master-security-kill-switch ${DEST_PATH}/secrets/slave-to-master-security-kill-switch

curl -sSL "http://${ADMIN_USR}:${ADMIN_PWD}@192.168.0.80:30500/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins" | \
  perl -pe 's/.*?<shortName>([\w-]+).*?<version>([^<]+)()(<\/\w+>)+/\1 \2\n/g'|sed 's/ /:/' > \
  ${DEST_PATH}/plugins.txt

cat << EOF > ${DEST_PATH}/executors.groovy
import jenkins.model.*
Jenkins.instance.setNumExecutors(0)
EOF

cat << EOF > ${DEST_PATH}/Dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update -y

COPY config.xml /usr/share/jenkins/ref/config.xml
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY jobs /usr/share/jenkins/ref/jobs
COPY secrets /usr/share/jenkins/ref/secrets
COPY users /usr/share/jenkins/ref/users
COPY plugins.txt /usr/share/jenkins/plugins.txt

# Workaround for 'Lockfile creation - File not found' error
RUN xargs /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
EOF

export IMG_NAME=jenkins-leader
export IMG_TAG=1.0

docker build -t ${IMG_NAME}:${IMG_TAG} ${DEST_PATH}
docker tag ${IMG_NAME}:${IMG_TAG} ${DOCKER_REGISTRY}/${IMG_NAME}:${IMG_TAG}
docker tag ${IMG_NAME}:${IMG_TAG} ${DOCKER_REGISTRY}/${IMG_NAME}:latest
docker push ${DOCKER_REGISTRY}/${IMG_NAME}:${IMG_TAG}
docker push ${DOCKER_REGISTRY}/${IMG_NAME}:latest
docker pull ${DOCKER_REGISTRY}/${IMG_NAME}:${IMG_TAG}
curl -X GET http://${DOCKER_REGISTRY}/v2/_catalog
curl -X GET http://${DOCKER_REGISTRY}/v2/jenkins-leader/tags/list
```

## 2. custom jenkins-leader 이용

### 1) jenkins-deployment 재구성

```sh
export DOCKER_REGISTRY=192.168.0.210:5000
export IMG_ORG=docker.io/jenkins/jenkins:lts
export IMG_NAME=jenkins-leader
export IMG_TAG=1.0

sed -i -e "s|image: .*|image: ${DOCKER_REGISTRY}/${IMG_NAME}:${IMG_TAG}|g" jenkins-deployment.yaml
kubectl apply -f ./jenkins-sa-clusteradmin-rbac.yaml -n ns-jenkins
kubectl apply -f ./jenkins-deployment.yaml -n ns-jenkins
kubectl get svc -n ns-jenkins
```

### 2) node-hello-world pipeline

- secret 생성

```sh
kubectl create secret -n ns-jenkins generic kube-config --from-file=$HOME/.kube/config
```

- svn 계정을 jenkins 에서 crendetials > System > Global credentials 에서 Add credentials 를 선택
- buildbot 계정으로 생성

- pipeline script

- svn co시 에러 발생 : svn: E170000: '${SVN_URL}' isn't in the same repository as '${SVN_URL}' , 즉 http 로 접근했는데, https 로 forwarding 하면서 발생한 문제로 파악됨
svn co --username=buildbot --password=jdnbuild --no-auth-cache --trust-server-cert --non-interactive ${SVN_URL}
- IP로 직접 접근시 성공
svn co --username=buildbot --password=jdnbuild --no-auth-cache --trust-server-cert --non-interactive ${SVN_IP_URL}
- svn checkout 은 http://192.168.0.80:30500/job/node-hello-world/pipeline-syntax/ 에서 checkout 항목을 선택하여 sample 을 확인하여 추가
- 다음을 pipline script 항목에 입력하고 설정한다
- plugin 중에서 blueocean을 추가로 설치하면 좀 더 보기 편한 UI 화면으로 전환

```script
podTemplate(
    containers: [
        containerTemplate(name: 'node', image: 'docker.io/node:10.16.0-stretch', ttyEnabled: true, command: 'cat'),
        , containerTemplate(name: 'docker', image: 'docker.io/docker:19.03.1', ttyEnabled: true, command: 'cat')
    ],
    volumes: [
        hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')
    ]
)
{
    node(POD_LABEL) {
        def DOCKER_REGISTRY = '192.168.0.210:5000'
        def IMG_NAME='node-hello-world'

        stage('svn checkout') {
            try {
                checkout([$class: 'SubversionSCM'
                    , additionalCredentials: []
                    , excludedCommitMessages: ''
                    , excludedRegions: ''
                    , excludedRevprop: ''
                    , excludedUsers: ''
                    , filterChangelog: false
                    , ignoreDirPropChanges: false
                    , includedRegions: ''
                    , locations: [[cancelProcessOnExternalsFail: true
                        , credentialsId: 'svn_budilbot'
                        , depthOption: 'infinity'
                        , ignoreExternalsOption: true
                        , local: '.'
                        , remote: '${SVN_URL}']
                    ]
                    , quietOperation: true
                    , workspaceUpdater: [$class: 'CheckoutUpdater']
                ])
            }
            catch(err) {
                println 'svn checkout failed: ${err}'
            }

            container('node') {
                stage('Build a node project') {
                    sh 'npm install'
                }
            }

            container('docker') {
                stage('Docker build image') {
                    script {
                        def IMG_VER = sh(script: 'cat index.js | grep "const version=" | grep -o "[0-9.]*"', returnStdout: true).trim()
                        dockerImage = docker.build("${DOCKER_REGISTRY}/${IMG_NAME}:${IMG_VER}.${env.BUILD_NUMBER}",  '-f ./Dockerfile .')
                    }
                }
                stage('Docker push') {
                    script {
                        docker.withRegistry('','') {
                            dockerImage.push()
                        }
                    }
                }
            }
        }
    }
}
```

- 스크립트 정상 여부는 pipeline script 로 확인한 후에, 안정화가 되면, Jenkinsfile 로 등록한 후에 pipeline script from SCM 으로 진행
- SCM 이므로, 이미 svn 설정이 되어 있으므로, checkout scm 으로만 수정

```groovy
#!groovy
podTemplate(
    containers: [
        containerTemplate(name: 'node', image: 'docker.io/node:10.16.0-stretch', ttyEnabled: true, command: 'cat'),
        , containerTemplate(name: 'docker', image: 'docker.io/docker:19.03.1', ttyEnabled: true, command: 'cat')
    ],
    volumes: [
        hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')
    ]
)
{
    node(POD_LABEL) {
        def DOCKER_REGISTRY = '192.168.0.210:5000'
        def IMG_NAME='node-hello-world'

        stage('Checkout') {
            checkout scm

            container('node') {
                stage('Build a node project') {
                    sh 'npm install'
                }
            }
            container('docker') {
                stage('Docker build image') {
                    script {
                        def IMG_VER = sh(script: 'cat index.js | grep "const version=" | grep -o "[0-9.]*"', returnStdout: true).trim()
                        dockerImage = docker.build("${DOCKER_REGISTRY}/${IMG_NAME}:${IMG_VER}.${env.BUILD_NUMBER}",  '-f ./Dockerfile .')
                    }
                }
                stage('Docker push') {
                    script {
                        docker.withRegistry('','') {
                            dockerImage.push()
                        }
                    }
                }
            }
        }
    }
}
```
