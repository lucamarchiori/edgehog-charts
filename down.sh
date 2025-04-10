kubectl delete all --all -n edgehog-dev
kubectl delete pvc --all -n edgehog-dev
kubectl delete secrets --all -n edgehog-dev
kubectl delete configmaps --all -n edgehog-dev
kubectl delete astarte astarte -n edgehog-dev
kubectl delete ingress.networking.k8s.io/edgehog-ingress -n edgehog-dev