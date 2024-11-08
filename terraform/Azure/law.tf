resource "azurerm_log_analytics_workspace" "logworkspace" {
  name                = "${var.project}-law"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "logsolution" {
  solution_name         = "Containers"
  workspace_resource_id = azurerm_log_analytics_workspace.logworkspace.id
  workspace_name        = azurerm_log_analytics_workspace.logworkspace.name
  location              = azurerm_resource_group.resourceGroup.location
  resource_group_name   = azurerm_resource_group.resourceGroup.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}

resource "random_integer" "rndno" {
  min = 1
  max = 500
}

// This will sometimes randomly fail depending on what already
// exists in target system. If you need it, else you have no
// conflicting logging setup
resource "azurerm_monitor_diagnostic_setting" "diagnostics" {
  count                      = (local.enable-logging) ? 1 : 0
  name                       = "${var.project}-audit-${random_integer.rndno.result}"
  target_resource_id         = azurerm_kubernetes_cluster.k8s_server.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logworkspace.id

  dynamic "enabled_log" {
    for_each = local.aks-config.diagnostics
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
