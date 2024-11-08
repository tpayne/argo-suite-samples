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

// If this one does not populate, wait a while then re-run this one
// using -target
resource "kubernetes_secret" "argocd-dex" {
  count = (var.iap_oauth_client_details != null) ? 1 : 0
  metadata {
    name      = "argocd-dex"
    namespace = var.argocd_namespace
  }
  data = {
    clientID     = var.iap_oauth_client_details.clientID
    clientSecret = var.iap_oauth_client_details.clientSecret
    url          = "frontend.${replace(var.nginxip, ".", "-", )}.nip.io"
  }
  type = "Opaque"
}
