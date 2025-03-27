helm uninstall --namespace edgehog-dev postgres
helm uninstall --namespace edgehog-dev minio
helm uninstall --namespace edgehog-dev cert-manager

kubectl delete all --all -n edgehog-dev
kubectl delete pvc --all -n edgehog-dev
kubectl delete secrets --all -n edgehog-dev
helm uninstall --namespace edgehog-dev edgehog