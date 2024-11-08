resource "kubernetes_service_account" "helm_account" {
  metadata {
    name      = var.helm_account
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "helm_role_binding" {
  metadata {
    name = kubernetes_service_account.helm_account.metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.helm_account.metadata.0.name
    namespace = "kube-system"
  }
  provisioner "local-exec" {
    command = "sleep 15"
  }
}

/*
 * Uncomment if you wish to use External-dns to manage DNS
 * You will need to config the installation once done
 *
 *
resource "helm_release" "external-dns" {
  name             = "external-dns"
  namespace        = "tools"
  recreate_pods    = true

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"

  set {
    name  = "google.project"
    value = var.project
  }

  set {
    name  = "provider"
    value = "google"
  }

  set {
    name  = "logLevel"
    value = "warning"
  }
}
*/

resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  recreate_pods    = true

  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
}

resource "helm_release" "nginx-ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  recreate_pods    = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
}
