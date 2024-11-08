
resource "azurerm_kubernetes_cluster" "k8s_server" {
  name                = "${var.project}-aks-001"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  dns_prefix          = "${var.project}-k8s"

  default_node_pool {
    name                = "${var.project}dp"
    vnet_subnet_id      = azurerm_subnet.subnet.id
    vm_size             = local.containers.machine_types.dev
    node_count          = local.aks-config.pool-type.node-count
    os_disk_size_gb     = local.aks-config.pool-type.disk_size
    type                = local.aks-config.pool-type.type
    enable_auto_scaling = local.aks-config.pool-type.auto-scaling
    min_count           = local.aks-config.pool-type.pool-min
    max_count           = local.aks-config.pool-type.pool-max
  }

  # You can specify private or whitelisted, but not both
  api_server_access_profile {
    authorized_ip_ranges = [local.network-firewall-config.control-cidr]
  }

  kubernetes_version = local.aks-config.aks-version

  identity {
    type = local.aks-config.identify
  }

  network_profile {
    network_plugin    = local.aks-config.network-profile.network_plugin
    load_balancer_sku = local.aks-config.network-profile.load_balancer_sku
  }

  sku_tier = local.containers.sku.free

  tags = var.tags

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "k8s_server_nodes" {
  name                  = "${var.project}np"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s_server.id
  vm_size               = local.containers.machine_types.dev
  vnet_subnet_id        = azurerm_subnet.subnet.id
  node_count            = local.aks-config.pool-type.node-count
  enable_auto_scaling   = local.aks-config.pool-type.auto-scaling
  min_count             = local.aks-config.pool-type.pool-min
  max_count             = local.aks-config.pool-type.pool-max
  orchestrator_version  = local.aks-config.aks-version
  priority              = local.aks-config.pool-type.priority
  os_type               = local.aks-config.pool-type.os-type
}
