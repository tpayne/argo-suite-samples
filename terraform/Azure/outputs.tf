output "kubernetes-information" {
  description = "Kubernetes server information"
  value = {
    allowed-cidrs = local.network-firewall-config.control-cidr
    endpoint-ip   = azurerm_kubernetes_cluster.k8s_server.fqdn
  }
}

output "allowed-ips" {
  description = "Allowed IP CIDRs"
  value       = concat([local.network-firewall-config.control-cidr], local.network-firewall-config.github-cidr)
}

output "argo-pwd" {
  description = "Argo admin password"
  sensitive   = true
  value       = data.external.argoPwd.result["argopwd"]
}

output "argo-token" {
  description = "Argo user token"
  sensitive   = true
  value       = data.external.argotoken.result["argotoken"]
}

output "ngnix-ip" {
  description = "External NGINX IP"
  value = {
    endpoint-ip = data.external.nginx-ip.result["nginxip"]
    endpoint-dns = "frontend.${replace(data.external.nginx-ip.result["nginxip"],
    ".", "-", )}.nip.io"
  }
}
