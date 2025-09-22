resource "kubernetes_secret" "github-token" {
  metadata {
    name      = "github-token"
    namespace = var.argocd_namespace
  }
  data = {
    token = var.git_details.git_token
    user  = var.git_details.git_user
    email = var.git_details.git_email
  }
  type = "Opaque"
}

resource "kubernetes_secret" "argocd-token" {
  metadata {
    name      = "argocd-token"
    namespace = var.argocd_namespace
  }
  data = {
    token = var.argocd_token
  }
  type = "Opaque"
}

