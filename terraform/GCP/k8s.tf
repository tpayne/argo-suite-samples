resource "google_container_cluster" "k8s_server" {
  name                = "${var.project}-gke-001"
  location            = var.region
  deletion_protection = false
  initial_node_count  = local.gke-config.gks-node-count

  network         = google_compute_network.network_vpc_network.self_link
  subnetwork      = google_compute_subnetwork.network_subnet.self_link
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.k8s_allocation.cluster_cidr
    services_ipv4_cidr_block = var.k8s_allocation.service_cidr
  }

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  cluster_autoscaling {
    enabled = true
    dynamic "resource_limits" {
      for_each = local.gke-config.autoscaling_resource_limits
      content {
        resource_type = lookup(resource_limits.value, "resource_type")
        minimum       = lookup(resource_limits.value, "minimum")
        maximum       = lookup(resource_limits.value, "maximum")
      }
    }
  }

  enable_shielded_nodes = true

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = local.network-firewall-config.control-cidr
      display_name = "External IP address"
    }
  }

  node_version       = local.gke-config.gke-version
  min_master_version = local.gke-config.gke-version

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  vertical_pod_autoscaling {
    enabled = true
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  timeouts {
    create = "75m"
    update = "75m"
    delete = "75m"
  }

  maintenance_policy {
    recurring_window {
      start_time = local.gke-config.maintenance_policy.start_time
      end_time   = local.gke-config.maintenance_policy.end_time
      recurrence = local.gke-config.maintenance_policy.recurrence
    }
  }

  node_config {
    service_account = google_service_account.default.email
    oauth_scopes    = local.gke-config.oauth_scopes

    tags = ["gke-node", "${var.project}-gke", "be-ingress"]
    labels = {
      env = var.project
    }

    disk_type    = local.gke-config.disk_type
    image_type   = local.containers.images.ubunto_container
    machine_type = local.containers.machine_types.prod
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "k8s_server_nodes" {
  name       = "${google_container_cluster.k8s_server.name}-np-001"
  location   = var.region
  cluster    = google_container_cluster.k8s_server.name
  node_count = local.gke-config.gks-node-count

  version = local.gke-config.gke-version

  node_config {
    service_account = google_service_account.default.email
    oauth_scopes    = local.gke-config.server_pool.oauth_scopes
    labels = {
      env = var.project
    }

    # preemptible  = true
    image_type   = local.containers.images.ubunto_container
    machine_type = local.containers.machine_types.prod
    tags         = ["gke-node", "${var.project}-gke", "be-ingress"]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = local.gke-config.server_pool.auto_repair
    auto_upgrade = local.gke-config.server_pool.auto_upgrade
  }
}

resource "google_service_account" "default" {
  account_id = "gke-sa"
}
