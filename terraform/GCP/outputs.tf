output "kubernetes-information" {
  description = "Kubernetes server information"
  value = {
    allowed-cidrs = google_container_cluster.k8s_server.master_authorized_networks_config
    endpoint-ip   = google_container_cluster.k8s_server.endpoint
  }
}

output "allowed-ips" {
  description = "Allowed IP CIDRs"
  value       = local.network-firewall-config.github-cidr
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
