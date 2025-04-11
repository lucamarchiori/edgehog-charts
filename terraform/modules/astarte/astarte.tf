terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

resource "kubernetes_namespace" "astarte-namespace" {
  metadata {
    name = "astarte"
  }
}

resource "kubernetes_namespace" "astarte-operator-namespace" {
  metadata {
    name = "astarte-operator"
  }
}

resource "helm_release" "astarte-operator" {
  chart      = "astarte-operator"
  name       = "astarte-operator"
  namespace  = "astarte-operator"
  repository = "https://helm.astarte-platform.org"
  version    = "v24.5.1"

  depends_on = [
    kubernetes_namespace.astarte-operator-namespace
  ]
}


resource "kubernetes_secret" "astarte-self-signed-cert" {
  metadata {
    name      = "astarte-tls-cert"
    namespace = "astarte"
  }

/* openssl req -x509 -newkey rsa:4096 -days 365 -sha256 -nodes \
  -keyout key.pem \
  -out crt.pem  \
  -subj '/CN=*.nip.io' */

  data = {
    "tls.crt" = file("${path.module}/crt.pem")
    "tls.key" = file("${path.module}/key.pem")
  }

  type = "kubernetes.io/tls"

  depends_on = [
    kubernetes_namespace.astarte-namespace
  ]
}

data "template_file" "astarte-cr" {
  template = file("${path.module}/astarte.tftpl")
  vars = {
    minikube_base_network_address = var.minikube_base_network_address
    scylla_ip                     = var.scylla_ip
  }
}

data "template_file" "adi-cr" {
  template = file("${path.module}/adi.tftpl")
  vars = {
    minikube_base_network_address = var.minikube_base_network_address
  }
}

resource "kubectl_manifest" "astarte-cr" {
  yaml_body = data.template_file.astarte-cr.rendered

  depends_on = [
    helm_release.astarte-operator,
    kubernetes_namespace.astarte-namespace,
    data.template_file.astarte-cr
  ]
}

resource "kubectl_manifest" "adi-cr" {
  yaml_body = data.template_file.adi-cr.rendered

  depends_on = [
    kubectl_manifest.astarte-cr,
    data.template_file.adi-cr
  ]
}

