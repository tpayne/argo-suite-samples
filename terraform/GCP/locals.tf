locals {
  helm-account-name = "helmsa"
  argocd_namespace  = "argocd"
  gitops-rep-options = {
    standard = "tpayne/argocd-autopilot"
    dex      = "tpayne/argocd-autopilot-dex"
  }
  gitops_repo = (length(data.github_repository.autopilot_repo) > 0) ? data.github_repository.autopilot_repo[0].git_clone_url : local.gitops-rep-options[lower(var.gitops_repo)]

  // network firewall
  network-firewall-config = {
    control-cidr = (var.access_cidr != null && length(var.access_cidr) > 0) ? var.access_cidr : "${data.external.routerip.result["ip"]}/32"
    //github-cidr = join(", ", [
    //  for addr in data.github_ip_ranges.githubips.hooks_ipv4 : jsonencode(addr)
    //])
    github-cidr = data.github_ip_ranges.githubips.hooks_ipv4
    allow = [
      {
        protocol = "tcp"
        ports    = ["80", "443", "6443", "8080-8085"]
      },
      {
        protocol = "icmp"
        ports    = []
      },
      {
        protocol = "udp"
        ports    = ["1-65535"]
      }
    ]
  }
  // GKE configuration
  gke-config = {
    gke-version    = "1.29.6-gke.1326000"
    gks-node-count = 2
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    disk_type = "pd-balanced"
    maintenance_policy = {
      start_time = "2021-05-10T23:00:00Z"
      end_time   = "2021-05-11T23:30:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU"
    }
    autoscaling_resource_limits = [
      {
        resource_type = "memory"
        minimum       = 16
        maximum       = 24
      },
      {
        resource_type = "cpu"
        minimum       = 2
        maximum       = 10
      }
    ]
    server_pool = {
      oauth_scopes = [
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/cloud-platform"
      ]
      auto_repair  = true
      auto_upgrade = true
    }
  }
  // Images to use
  containers = {
    machine_types = {
      dev  = "f1-micro"
      test = "n1-highcpu-32"
      prod = "n1-standard-1"
    }
    images = {
      cos              = "cos-cloud/cos-stable"
      minimal          = "cos-cloud/cos-stable"
      deb              = "debian-cloud/debian-9"
      ubunto           = "ubuntu-os-cloud/ubuntu-1804-lts"
      ubunto_container = "ubuntu_containerd"
    }
  }
  // K8s context
  k8s_context = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = google_container_cluster.k8s_server.name
      cluster = {
        certificate-authority-data = google_container_cluster.k8s_server.master_auth.0.cluster_ca_certificate
        server                     = google_container_cluster.k8s_server.endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = google_container_cluster.k8s_server.name
        user    = data.google_client_openid_userinfo.terraform_user.email
      }
    }]
    users = [{
      name = data.google_client_openid_userinfo.terraform_user.email
      user = {
        token = data.google_client_config.client.access_token
      }
    }]
  })
}
