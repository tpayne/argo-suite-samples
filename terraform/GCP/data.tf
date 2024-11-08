data "external" "routerip" {
  program = ["bash", "-c", "curl -s 'https://api64.ipify.org?format=json'"]
}

data "external" "argotoken" {
  depends_on = [
    google_container_cluster.k8s_server,
    null_resource.deploy_argo,
    data.external.argoPwd
  ]
  program = ["sh", "-c", <<EOF
  (kubectl port-forward -n \
    argocd svc/argocd-server 8080:80 > /dev/null 2>&1)&
  kubePid="$!"
  sleep 10
  argocd login localhost:8080 --insecure --username admin \
    --password "$(kubectl get secret argocd-initial-admin-secret \
    -n "${local.argocd_namespace}" -o jsonpath="{.data.password}" \
    | base64 -d)" >> /tmp/argocd$$.log 2>&1
  sleep 10
  echo "{\"argotoken\":\"$(argocd account generate-token \
    --account argorunner)\"}"
  sleep 10
  kill \$kubePid
  sleep 5
  exit 0
  EOF
  ]
}

data "external" "argoPwd" {
  depends_on = [
    google_container_cluster.k8s_server,
    null_resource.deploy_argo
  ]
  program = ["bash", "-c", <<EOF
  echo "{\"argopwd\":\"$(kubectl get secret argocd-initial-admin-secret \
      -n "${local.argocd_namespace}" \
      -o jsonpath="{.data.password}" | base64 -d)\"}"
  EOF
  ]
}

data "external" "nginx-ip" {
  depends_on = [
    google_container_cluster.k8s_server,
    module.helmDeploy
  ]
  program = ["bash", "-c", <<EOF
  sleep 5
  echo "{\"nginxip\":\"$(kubectl get svc/ingress-nginx-controller \
      -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}")\"}"
  EOF
  ]
}

data "external" "iap-brand" {
  program = ["bash", "-c", <<EOF
  gcloud services enable iap.googleapis.com
  echo "{$(gcloud iap oauth-brands list \
    --project="${var.project}" \
    --format json | grep '"name":' | rev | \
    cut -c2- | rev)}"
  EOF
  ]
}

data "google_client_config" "client" {}

data "google_client_openid_userinfo" "terraform_user" {}

data "github_ip_ranges" "githubips" {}

data "github_repository" "autopilot_repo" {
  count     = (strcontains(local.gitops-rep-options[lower(var.gitops_repo)], "https://")) ? 0 : 1
  full_name = local.gitops-rep-options[lower(var.gitops_repo)]
}

data "local_file" "iap_oauth_client_details" {
  count      = (fileexists("${path.module}/iap_id.txt")) ? 1 : 0
  filename   = "${path.module}/iap_id.txt"
  depends_on = [null_resource.iap]
}

data "google_project" "project" {
  project_id = var.project
}
