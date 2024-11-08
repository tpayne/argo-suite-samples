# Create a network VPC network...
resource "google_compute_network" "network_vpc_network" {
  name                    = "${var.project}-vpc-be-001"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

# Subnet network layer
resource "google_compute_subnetwork" "network_subnet" {
  name                     = "${var.project}-subnet-be-001"
  region                   = var.region
  network                  = google_compute_network.network_vpc_network.name
  ip_cidr_range            = var.network_cidr
  private_ip_google_access = true
}

# Firewall rules
resource "google_compute_firewall" "allownetwork_ingress" {
  name      = "${var.project}-allow-be"
  network   = google_compute_network.network_vpc_network.self_link
  direction = "INGRESS"

  dynamic "allow" {
    for_each = local.network-firewall-config.allow
    content {
      protocol = lookup(allow.value, "protocol")
      ports    = lookup(allow.value, "ports")
    }
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  source_ranges = concat([local.network-firewall-config.control-cidr], local.network-firewall-config.github-cidr)
  target_tags   = ["be-ingress"]
}
