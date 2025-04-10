
# Script for development purposes only
minikube addons enable metallb

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add cert-manager https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add astarte https://helm.astarte-platform.org
helm repo update

# Install Dependencies
echo "Installing nginx-ingress..."
helm install --namespace edgehog-dev --create-namespace ingress-nginx ingress-nginx/ingress-nginx --version 4.11.0
echo "Installing cert-manager..."
helm install --namespace edgehog-dev cert-manager cert-manager/cert-manager --version 1.17.1 --set crds.enabled=true
echo "Installing PostgreSQL..."
helm install --namespace edgehog-dev --create-namespace postgres bitnami/postgresql --version 16.5.6
echo "Installing MinIO..."
helm install --namespace edgehog-dev --create-namespace minio bitnami/minio --version 15.0.7
echo "Installing Astarte..."
helm install --namespace edgehog-dev --create-namespace astarte-operator astarte/astarte-operator --version 24.5.1

export POSTGRES_PASSWORD=$(kubectl get secret --namespace edgehog-dev postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
export MINIO_ROOT_USER=$(kubectl get secret --namespace edgehog-dev minio -o jsonpath="{.data.root-user}" | base64 -d)
export MINIO_ROOT_PASSWORD=$(kubectl get secret --namespace edgehog-dev minio -o jsonpath="{.data.root-password}" | base64 -d)

# CONFIGURE METALLB TO USE MINIKUBE IP ADDRESS RANGE

export MK_BASE_NETWORK_ADDRESS=$(minikube ip | sed 's/\.[0-9]*$//')
kubectl -n metallb-system delete configmaps config
kubectl -n metallb-system apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: config
  namespace: metallb-system
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${MK_BASE_NETWORK_ADDRESS}.150-${MK_BASE_NETWORK_ADDRESS}.250
EOF

# WAIT FOR LOAD BALANCER TO GET CONFIGURED
sleep 5s

# EXPORT DOMAINS WITH LOAD BALANCER IP
export LB_IP=$(kubectl -n edgehog-dev get service ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
export HOST_FRONTEND="edgehog.${LB_IP}.nip.io"
export HOST_BACKEND="api.edgehog.${LB_IP}.nip.io"
export HOST_DEVICE_FORWARDER="forwarder.edgehog.${LB_IP}.nip.io"

export ASTARTE_DASHBOARD_HOST="dashboard.astarte.${LB_IP}.nip.io"
export ASTARTE_API_HOST="api.astarte.${LB_IP}.nip.io"
export ASTARTE_BROKER_HOST="broker.astarte.${LB_IP}.nip.io"

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

helm install --namespace edgehog-dev \
      --set frontend.host=${HOST_FRONTEND} \
      --set backend.host=${HOST_BACKEND} \
      --set deviceForwarder.host=${HOST_DEVICE_FORWARDER} \
      edgehog ./chart

# Handle Astarte deployment

# Create a Realm (test) keypair
astartectl utils gen-keypair test

# Create a Housekeeping keypair
astartectl utils gen-keypair housekeeping

# Create the Realm
astartectl housekeeping realms create test --astarte-url ${ASTARTE_API_HOST} --realm-public-key test_public.pem -k housekeeping_private.pem

# Create SSL certificates for .nip.io domains
openssl req -x509 -newkey rsa:4096 -days 365 -sha256 -nodes \
  -keyout privkey.pem \
  -out cert.pem  \
  -subj '/CN=*.nip.io'

kubectl create secret tls astarte-tls-cert -n edgehog-dev --cert=cert.pem --key=privkey.pem

# Deploy astarte with custom values (set as environment variables)
envsubst < astarte-sample.yaml | kubectl apply -f -

# Output endpoints
echo "EDGEHOG Frontend: ${HOST_FRONTEND}"
echo "EDGEHOG Backend: ${HOST_BACKEND}"
echo "EDGEHOG Device forwarder: ${HOST_DEVICE_FORWARDER}"

echo "ASTARTE Dashboard: ${ASTARTE_DASHBOARD_HOST}"
echo "ASTARTE API: ${ASTARTE_API_HOST}"