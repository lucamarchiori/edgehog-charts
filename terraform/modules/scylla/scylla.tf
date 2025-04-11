resource "helm_release" "scylla_operator" {
  name             = "scylla-operator"
  repository       = "https://scylla-operator-charts.storage.googleapis.com/stable"
  chart            = "scylla-operator"
  namespace        = "scylla-operator"
  create_namespace = true
}

resource "helm_release" "scylla_cluster" {
  name             = "scylla"
  repository       = "https://scylla-operator-charts.storage.googleapis.com/stable"
  chart            = "scylla"
  namespace        = "scylla"
  create_namespace = true
  depends_on = [helm_release.scylla_operator]

  set {
    name  = "cluster.datacenter.racks[0].storage.capacity"
    value = "5Gi"
  }

  set {
    name  = "cluster.datacenter.racks[0].storage.storageClassName"
    value = "standard"
  }

  set {
    name  = "cluster.datacenter.racks[0].members"
    value = "1"
  }
}
