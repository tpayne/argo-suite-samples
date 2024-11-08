resource "null_resource" "deploy_argo" {
  depends_on = [
    module.helmDeploy
  ]

  triggers = {
    gitops_repo = replace(local.gitops_repo, "git://", "https://")
    git_token   = var.git_details.git_token
    k8s_server  = azurerm_kubernetes_cluster.k8s_server.name
    resouce_grp = azurerm_kubernetes_cluster.k8s_server.resource_group_name
  }

  # Run the argo auto pilot deploy...
  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    working_dir = path.module
    command     = <<-EOT
        echo "Cloning repo ${self.triggers.gitops_repo}" \
          > /tmp/argocd$$.log 2>&1 &&
        az aks get-credentials \
            --name \
            "${self.triggers.k8s_server}" \
            --resource-group \
            "${self.triggers.resouce_grp}" \
            --overwrite-existing && \
        argocd-autopilot repo bootstrap --recover \
            >> /tmp/argocd$$.log 2>&1
    EOT
    environment = {
      GIT_TOKEN = "${self.triggers.git_token}"
      GIT_REPO  = "${self.triggers.gitops_repo}"
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/sh", "-c"]
    working_dir = path.module
    command     = <<-EOT
        true
    EOT
    environment = {
      GIT_TOKEN = "${self.triggers.git_token}"
      GIT_REPO  = "${self.triggers.gitops_repo}"
    }
  }
}

module "k8sDeploy" {
  source = "../modules/k8sDeploy"

  depends_on = [
    null_resource.deploy_argo,
    data.external.nginx-ip,
    data.external.argotoken
  ]

  argocd_namespace = local.argocd_namespace
  argocd_token     = data.external.argotoken.result["argotoken"]
  nginxip          = data.external.nginx-ip.result["nginxip"]
  git_details      = var.git_details
}
