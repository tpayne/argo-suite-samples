resource "google_project_service" "project_service" {
  count   = (var.gitops_repo == "dex") ? 1 : 0
  project = data.google_project.project.project_id
  service = "iap.googleapis.com"
}

resource "google_iap_brand" "project_brand" {
  count             = (length(data.external.iap-brand.result["name"]) > 0) ? 0 : 1
  support_email     = data.google_client_openid_userinfo.terraform_user.email
  application_title = "${var.project} Cloud IAP protected Application"
  project           = (length(google_project_service.project_service) > 0) ? google_project_service.project_service[0].project : ""
}

resource "google_iap_client" "iapoauth" {
  count        = (var.gitops_repo == "dex") ? 1 : 0
  display_name = "IAP OAuth"
  brand        = (length(data.external.iap-brand.result["name"]) > 0) ? data.external.iap-brand.result["name"] : google_iap_brand.project_brand[0].name
}

resource "null_resource" "iap" {
  count = (var.gitops_repo == "dex") ? 1 : 0
  triggers = {
    display_name = "IAP Client OAuth"
    brand_id     = (length(data.external.iap-brand.result["name"]) > 0) ? data.external.iap-brand.result["name"] : google_iap_brand.project_brand[0].name
  }

  # Run the gcloud version for IAP. TF one is dodgy...
  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    working_dir = path.module
    command     = <<-EOT
      gcloud services enable iap.googleapis.com
      if [ ! -f "iap_id.txt" ]; then
        gcloud iap oauth-clients create \
            ${self.triggers.brand_id} \
            --display_name="${self.triggers.display_name}" \
            >> "${path.module}/iap_id.txt"
        fi
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/sh", "-c"]
    working_dir = path.module
    command     = <<-EOT
        true
    EOT
  }
}
