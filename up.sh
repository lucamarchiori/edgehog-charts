
# Script for development purposes only
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add cert-manager https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Install Dependencies
echo "Installing nginx-ingress..."
helm install --namespace edgehog-dev ingress-nginx ingress-nginx/ingress-nginx --version 4.11.0
echo "Installing PostgreSQL..."kgpa
helm install --namespace edgehog-dev --create-namespace postgres bitnami/postgresql --version 16.5.6
echo "Installing MinIO..."
helm install --namespace edgehog-dev --create-namespace minio bitnami/minio --version 15.0.7
echo "Installing cert-manager..."
helm install --namespace edgehog-dev cert-manager cert-manager/cert-manager --version 1.17.1 --set crds.enabled=true

export POSTGRES_PASSWORD=$(kubectl get secret --namespace edgehog-dev postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
export MINIO_ROOT_USER=$(kubectl get secret --namespace edgehog-dev minio -o jsonpath="{.data.root-user}" | base64 -d)
export MINIO_ROOT_PASSWORD=$(kubectl get secret --namespace edgehog-dev minio -o jsonpath="{.data.root-password}" | base64 -d)

kubectl create secret generic -n edgehog-dev edgehog-db-connection \
  --from-literal="database=postgres" \
  --from-literal="username=postgres" \
  --from-literal="password=$POSTGRES_PASSWORD"

kubectl create secret generic -n edgehog-dev edgehog-minio-connection \
  --from-literal="minio-root-user=$MINIO_ROOT_USER" \
  --from-literal="minio-root-password=$MINIO_ROOT_PASSWORD"

kubectl create secret generic -n edgehog-dev  edgehog-secret-key-base \
  --from-literal="secret-key-base=$(openssl rand -base64 48)"

kubectl create secret generic -n edgehog-dev edgehog-device-forwarder-secret-key-base \
  --from-literal="secret-key-base=$(openssl rand -base64 48)"

helm install --namespace edgehog-dev edgehog .

