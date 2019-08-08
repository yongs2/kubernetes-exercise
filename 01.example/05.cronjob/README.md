# [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)

## 실행

```sh
wget --no-check-certificate https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/application/job/cronjob.yaml

kubectl create -f https://k8s.io/examples/application/job/cronjob.yaml
```

## 동작 확인

```sh
kubectl get cronjob hello
kubectl get jobs --watch

pods=$(kubectl get pods --selector=job-name=hello-4111706356 --output=jsonpath={.items[].metadata.name})
kubectl logs $pods
```

## 제거

```sh
kubectl delete cronjob hello
```
