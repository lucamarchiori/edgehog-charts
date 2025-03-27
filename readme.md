For local development:

Create a new Kubernetes namespace:
```sh
kubectl create namespace edgehog
```

## MinIO on Docker

Pull a new Docker MinIO image or use an existing one.
```sh
mkdir -p ~/minio/data

docker run \
   -p 9000:9000 \
   -p 9001:9001 \
   --name minio \
   -v ~/minio/data:/data \
   -e "MINIO_ROOT_USER=ROOTNAME" \
   -e "MINIO_ROOT_PASSWORD=CHANGEME123" \
   quay.io/minio/minio server /data --console-address ":9001" -d
```

Create the secret containing the details for the MinIO connection:
```sh
kubectl create secret generic -n edgehog edgehog-minio-connection \
  --from-literal="minio-root-user=ROOTNAME" \
  --from-literal="minio-root-password=CHANGEME123"
```

## PostgreSQL on Docker

Pull a new Docker PostgreSQL image or use an existing one.

```sh
docker run --name some-postgres \
    -p 127.0.0.1:5432:5432 \
    -e POSTGRES_PASSWORD=mysecretpassword \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_DB=postgres \
    -d postgres
```

Create the secret containing the details for the PostgreSQL connection:
```sh
kubectl create secret generic -n edgehog edgehog-db-connection \
  --from-literal="database=postgres" \
  --from-literal="username=postgres" \
  --from-literal="password=mysecretpassword"
```

## Secrets
This command creates the secret key base used by Phoenix for the backend:
```sh
kubectl create secret generic -n edgehog edgehog-secret-key-base \
  --from-literal="secret-key-base=$(openssl rand -base64 48)"
```

Another secret key base can be generated for the device forwarder:
```sh
kubectl create secret generic -n edgehog edgehog-device-forwarder-secret-key-base \
  --from-literal="secret-key-base=$(openssl rand -base64 48)"
```