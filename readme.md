## Local installation (development purposes only)
Requirements:
- Minikube
- Helm
- Kubectl

Start Minikube
```bash
minikube start --memory=10000 --cpus=4 --driver=virtualbox --addons metallb ingress && minikube addons enable metallb
```

The installation script deploy all the dependencies and Edgehog itself in the "edgehog-dev" namespace. Feel free to edit the scripts to change the namespace.
If you get `"INSTALLATION FAILED: cannot re-use a name that is still in use"` please run `./down.sh` script to remove duplicated or conflicting components. The same script can be used to remove all the components installed. 

Run installation script:
```bash
./up.sh
```

Delete the whole deployment:
```bash
./down.sh
```


## Chart installation

### Hosts
Head to your DNS provider and
point three domains (one for the backend, one for the frontend, and one for the [Device Forwarder](https://github.com/edgehog-device-manager/edgehog_device_forwarder)) to that IP address.

Save the three hosts in the `values.yam` (e.g. `api.edgehog.example.com`, `edgehog.example.com`, and `forwarder.edgehog.example.com`).


### Secrets
#### Database connection
```bash
$ kubectl create secret generic -n edgehog edgehog-db-connection \
  --from-literal="database=<DATABASE-NAME>" \
  --from-literal="username=<DATABASE-USER>" \
  --from-literal="password=<DATABASE-PASSWORD>"
```

Values to be replaced
- `DATABASE-NAME`: the name of the PostgreSQL database.
- `DATABASE-USER`: the username to access the database.
- `DATABASE-PASSWORD`: the password to access the database.

#### Secret key base
This command creates the secret key base used by Phoenix for the backend:

```bash
$ kubectl create secret generic -n edgehog edgehog-secret-key-base \
  --from-literal="secret-key-base=$(openssl rand -base64 48)"
```

Another secret key base can be generated for the device forwarder:

```bash
$ kubectl create secret generic -n edgehog edgehog-device-forwarder-secret-key-base \
  --from-literal="secret-key-base=$(openssl rand -base64 48)"
```

#### S3 Credentials (Google Cloud)

To use GCP S3, ensure that the `s3` section in `values.yam` is configured with the appropriate parameters and that `s3.provider` is set to `gcp`.

To create an S3-compatbile bucket on Google Cloud to be used with Edgehog, the following steps have
to be performed:

- [Create a service
  account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating) in your
  project.

- [Create JSON
credentials](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating) for
the service account and rewrite them as a single line JSON:

```bash
$ gcloud iam service-accounts keys create service_account_credentials.json \
  --iam-account=<SERVICE-ACCOUNT-EMAIL>
$ cat service_account_credentials.json | jq -c > s3_credentials.json
```

- [Create a Cloud Storage Bucket](https://cloud.google.com/storage/docs/creating-buckets) on GCP
   * Choose a multiregion in the preferred zones (e.g. Europe)
   * Remove public access prevention
   * Choose a fine-grained Access Control, instead of a uniform one

- After making sure of having the right project selected for the `gcloud` CLI, assign the
`objectAdmin` permission to the service account for the newly created bucket:

```bash
$ gsutil iam ch serviceAccount:<SERVICE-ACCOUNT-EMAIL>:objectAdmin gs://<BUCKET-NAME>
```

- Create a secret containing the service account credentials

```bash
kubectl create secret generic -n edgehog edgehog-s3-credentials \
  --from-file="gcp-credentials=s3_credentials.json"
```

Values to be replaced
- `SERVICE-ACCOUNT-EMAIL`: the email associated with the service account.
- `BUCKET-NAME`: the bucket name for the S3 storage.

#### S3 Credentials (MinIO)

To use MinIO S3, ensure that the `s3` section in `values.yam` is configured with the appropriate parameters and that `s3.provider` is set to `minio`.

This command creates the secret containing the S3 credentials:

```bash
kubectl create secret generic -n edgehog-dev edgehog-minio-connection \
  --from-literal="minio-root-user=$MINIO_ROOT_USER" \
  --from-literal="minio-root-password=$MINIO_ROOT_PASSWORD"
```

Values to be replaced
- `MINIO_ROOT_USER`: the user for MinIO S3 storage.
- `MINIO_ROOT_PASSWORD`: the password for MinIO S3 storage.

#### S3 Credentials (Generic)

Consult the documentation of your cloud provider for more details about obtaining an access key ID
and a secret access key for your S3-compatible storage.

This command creates the secret containing the S3 credentials:

```bash
$ kubectl create secret generic -n edgehog edgehog-s3-credentials \
  --from-literal="access-key-id=<ACCESS-KEY-ID>" \
  --from-literal="secret-access-key=<SECRET-ACCESS-KEY>"
```

Values to be replaced
- `ACCESS-KEY-ID`: the access key ID for your S3 storage.
- `SECRET-ACCESS-KEY`: the secret access key for your S3 storage.


## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backend.host | string | `"api.edgehog.customdomain.com"` | host of the Edgehog backend |
| backend.maxUploadSizeBytes | int | `2048` | maxUploadSizeBytes is the maximum dimension for uploads, particularly relevant for OTA updates. If omitted, it defaults to 4 Gigabytes. |
| database.hostname | string | `"postgres-postgresql.edgehog-dev.svc.cluster.local"` | hostname of the PostgreSQL database. |
| deviceForwarder.host | string | `"forwarder.edgehog..customdomain.com"` | host of the device forwarder. It should only contain the hostname without the http:// or https:// scheme |
| deviceForwarder.port | int | `443` | port for the instance of Edgehog Device Forwarder. It defaults to 443 |
| deviceForwarder.secureSessions | bool | `true` | secureSessions can be either true or false, it indicates whether devices use TLS to connect to the Edgehog Device Forwarder |
| enabledSecrets.googleGeocoding | bool | `false` |  |
| enabledSecrets.googleGeolocation | bool | `false` |  |
| enabledSecrets.ipbase | bool | `false` |  |
| frontend.host | string | `"edgehog.customdomain.com"` | host of the frontend |
| letsencrypt.email | string | `"admin@example.com"` | email address that will be used for the ACME account for LetsEncrypt |
| namespace | string | `"edgehog-dev"` | namespace of the Edgehog deployment. By default everything is deployed to the edgehog namespace in the Kubernetes cluster, but Edgehog can be deployed in any namespace |
| s3.assetHost | string | `"test"` | assetHost for the S3 storage, e.g. storage.googleapis.com/<S3-BUCKET> for GCP or <S3-BUCKET>.s3.amazonaws.com for AWS. |
| s3.bucket | string | `"test"` | bucket name for the S3 storage. |
| s3.host | string | `"test"` | host for the S3 storage |
| s3.port | string | `"test"` | port for the S3 storage. This has to be put in double quotes to force it to be interpreted as a string. |
| s3.provider | string | `"minio"` | provider of S3 storage. Curretnly can be set to "gcp"  (Google Cloud) or " minio"  |
| s3.region | string | `"test"` | region where the S3 storage resides. |
| s3.scheme | string | `"http"` | scheme (http or https) for the S3 storage |

----------------------------------------------