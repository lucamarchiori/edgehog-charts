helm uninstall --namespace edgehog-dev postgres
helm uninstall --namespace edgehog-dev minio
helm uninstall --namespace edgehog-dev cert-manager
helm uninstall --namespace edgehog-dev edgehog
helm uninstall --namespace edgehog-dev ingress-nginx

kubectl delete all --all -n edgehog-dev
kubectl delete pvc --all -n edgehog-dev
kubectl delete secrets --all -n edgehog-dev

minikube tunnel -c