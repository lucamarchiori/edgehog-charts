
resource "helm_release" "scylla-operator" {
  chart      = "scylla-operator"
  name       = "scylla-operator"
  namespace  = "scylla-operator"
  repository = "https://storage.googleapis.com/scylla-operator-charts/stable"
  create_namespace = true
}

resource "helm_release" "scylla" {
  chart      = "scylla"
  name       = "scylla"
  namespace  = "scylla"
  repository = "https://storage.googleapis.com/scylla-operator-charts/stable"
  create_namespace = true
  depends_on = [
    helm_release.scylla-operator,
  ]
}

# resource "helm_release" "scylla-manager" {
#   chart      = "scylla-manager"
#   name       = "scylla-manager"
#   namespace  = "scylla-manager"
#   repository = "https://storage.googleapis.com/scylla-operator-charts/stable"
#   create_namespace = true
#   depends_on = [
#     helm_release.scylla-operator,
#     helm_release.scylla,
#   ]
# }