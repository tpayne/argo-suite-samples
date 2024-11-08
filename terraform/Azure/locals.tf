locals {
  helm-account-name = "helmsa"
  argocd_namespace  = "argocd"
  gitops-rep-options = {
    standard = "tpayne/argocd-autopilot"
    dex      = "tpayne/argocd-autopilot-dex"
  }
  gitops_repo   = (length(data.github_repository.autopilot_repo) > 0) ? data.github_repository.autopilot_repo[0].git_clone_url : local.gitops-rep-options[lower(var.gitops_repo)]
  allowed-cidrs = "[${local.network-firewall-config.control-cidr},${join(", ", [for s in local.network-firewall-config.github-cidr : format("%q", s)])}]"

  // network firewall
  network-firewall-config = {
    control-cidr = (var.access_cidr != null && length(var.access_cidr) > 0) ? var.access_cidr : "${data.external.routerip.result["ip"]}/32"
    //github-cidr = join(", ", [
    //  for addr in data.github_ip_ranges.githubips.hooks_ipv4 : jsonencode(addr)
    //])
    github-cidr = data.github_ip_ranges.githubips.hooks_ipv4
    allow = [
      {
        protocol = "Tcp"
        priority = 1000
        ports    = ["80", "443", "6443", "8080-8085"]
      },
      {
        protocol = "Udp"
        priority = 1001
        ports    = ["1-65535"]
      }
    ]
  }

  enable-logging = false

  // AKS configuration
  aks-config = {
    diagnostics = [
      "kube-apiserver",
      "kube-controller-manager",
      "cluster-autoscaler",
      "kube-scheduler",
      "kube-audit"
    ]
    aks-version = "1.29.4"
    identify    = "SystemAssigned"
    pool-type = {
      node-count   = 2
      disk_size    = 30
      pool-min     = 2
      pool-max     = 3
      type         = "VirtualMachineScaleSets"
      auto-scaling = true
      priority     = "Regular"
      os-type      = "Linux"
    }
    network-profile = {
      network_plugin    = "azure"
      load_balancer_sku = "standard"
    }
  }

  // Images to use
  containers = {
    machine_types = {
      dev  = "Standard_D2_v2"
      test = "Standard_D2as_v4"
      prod = "Standard_D8s_v3"
    }
    sku = {
      free    = "Free"
      westus2 = "16.04-LTS"
      eastus  = "18.04-LTS"
    }
  }
  // K8s context
  k8s_context = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = azurerm_kubernetes_cluster.k8s_server.name
      cluster = {
        certificate-authority-data = azurerm_kubernetes_cluster.k8s_server.kube_config.0.cluster_ca_certificate
        server                     = azurerm_kubernetes_cluster.k8s_server.fqdn
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = azurerm_kubernetes_cluster.k8s_server.name
        user    = data.azuread_user.terraform_user.mail
      }
    }]
    users = [{
      name = data.azuread_user.terraform_user.mail
      user = {
        token = base64decode(azurerm_kubernetes_cluster.k8s_server.kube_config.0.client_key)
      }
    }]
  })
}
