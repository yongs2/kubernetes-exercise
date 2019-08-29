kubectl describe $(kubectl get secret --all-namespaces -o name | grep cluster-admin-dashboard) | grep "token: "
