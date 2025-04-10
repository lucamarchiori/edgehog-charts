terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
  }
}

provider "kubernetes" {
  config_path  = "~/.kube/config"
  config_context = "minikube"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

resource "helm_release" "metallb" {
  chart      = "metallb"
  name       = "metallb"
  namespace  = "metallb-system"
  create_namespace = true
  repository = "https://charts.bitnami.com/bitnami"
  version    = "4.1.13"
}

data "template_file" "ip-address-pool" {
  template = file("${path.module}/address-pool.tftpl")
  vars = {
    minikube_base_network_address = var.minikube_base_network_address
  }
}

resource "kubectl_manifest" "metallb-ip-address-pool" {
  yaml_body = data.template_file.ip-address-pool.rendered

  depends_on = [
    helm_release.metallb,
    data.template_file.ip-address-pool
  ]
}

resource "helm_release" "cert-manager" {
  chart      = "cert-manager"
  name       = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  repository = "https://charts.jetstack.io"
  version    = "v1.10.0" # Keeping the specific version for now

  set {
    name  = "installCRDs"
    value = true
  }
}

output "cert_manager_helm_release_name" {
  value = helm_release.cert-manager.name
}

resource "helm_release" "ingress-nginx" {
  chart      = "ingress-nginx"
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "4.11.5"
  create_namespace = true

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  # Consider removing this and letting MetalLB assign an IP if not strictly necessary
  # set {
  #   name  = "controller.service.loadBalancerIP"
  #   value = "${var.minikube_base_network_address}.100"
  # }

  depends_on = [
    kubectl_manifest.metallb-ip-address-pool,
  ]
}

module "scylla" {
  source                      = "./modules/scylla"
  depends_on = [
    helm_release.cert-manager,
    helm_release.ingress-nginx,
  ]
}

module "astarte" {
  source                      = "./modules/astarte"
  minikube_base_network_address = var.minikube_base_network_address
  scylla_ip                   = var.scylla_ip
  depends_on = [
    helm_release.cert-manager,
    helm_release.ingress-nginx,
  ]
}