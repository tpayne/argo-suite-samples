provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}

provider "github" {
  token = var.git_details.git_token
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.k8s_server.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s_server.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8s_server.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s_server.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.k8s_server.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s_server.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.k8s_server.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s_server.kube_config.0.cluster_ca_certificate)
  }
}
