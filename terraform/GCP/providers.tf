provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.k8s_server.endpoint}"
  token                  = data.google_client_config.client.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.k8s_server.master_auth.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = google_container_cluster.k8s_server.endpoint
    token                  = data.google_client_config.client.access_token
    client_certificate     = base64decode(google_container_cluster.k8s_server.master_auth.0.client_certificate)
    client_key             = base64decode(google_container_cluster.k8s_server.master_auth.0.client_key)
    cluster_ca_certificate = base64decode(google_container_cluster.k8s_server.master_auth.0.cluster_ca_certificate)
  }
}

provider "github" {
  token = var.git_details.git_token
}