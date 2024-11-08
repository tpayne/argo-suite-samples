## Introduction

This repository contains Terraform code that will...

* Deploy a GKE environment (with a default firewall setup)
* Deploy a couple of facilitator Helm charts like Nginx, External DNS and External Secrets
* Deploy runtime Kubernetes secrets
* Deploy a standard Argo-suite via `autopilot`

## Usage

To install the system, review the variables that you want to use to configure the installation. The main variables to consider are the following: -

* `gitops_repo` - Used to control the type of Argo suite deployed
* `git_details.git_token` - Used to manage the GH token used to interact with Github
* `git_details.git_user` - Used to manage the user used for GH commits
* `git_details.git_email` - Used to manage the user email used for GH commits

Currently, the `gitops_repo` variable only supports `standard`, but you can extend it by customising your own autopilot repo and adding it to the TF map in `locals.tf`

For example...

```hcl
  gitops-rep-options = {
    standard = "tpayne/argocd-autopilot"
  }
```

A typical `terraform.tfvars` might look like...

```hcl
project      = "thisismytestproject"
network_cidr = "10.2.0.0/21"

// GH details
git_details = {
  git_token  = "ghp_abcdefghijk12345"
  git_user   = "githubuser"
  git_email  = "githubuser@users.noreply.github.com"
}

gitops_repo = "standard"
```

## Firewalls

By default, the firewall is deployed to only allow connections from the external IP you ran the installation from and any IPs associated with the GH servers. These values are looked up dynamically using `data` blocks.

If you wish to modify the firewall rules, then you will need to change the module as appropriate.

## Installed Executables

The Terraform used for deployment makes use of a number of executables that must be preinstalled on your system.

These are: -

* `curl`
* `gcloud`
* `argocd`
* `kubectl`
* `helm`

Failure to install these executables will cause the deployment to fail.

## References

The following are refereneces which might be of interest

* https://github.com/tpayne/argo-suite-samples.git
* https://github.com/tpayne/argocd-autopilot.git

## Known Issues

The following are known issues or limitations.

* Currently, the installation only uses a standard Argo RBAC and server authentication module. IAP and SSO (via Dex) is not currently supported, but will be added time allowing

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.3.1 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.74.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.2 |
| <a name="provider_github"></a> [github](#provider\_github) | 5.42.0 |
| <a name="provider_google"></a> [google](#provider\_google) | 5.10.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_helmDeploy"></a> [helmDeploy](#module\_helmDeploy) | ../modules/helmDeploy | n/a |
| <a name="module_k8sDeploy"></a> [k8sDeploy](#module\_k8sDeploy) | ../modules/k8sDeploy | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.allownetwork_ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.network_vpc_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.network_subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_container_cluster.k8s_server](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |
| [google_container_node_pool.k8s_server_nodes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [google_iap_brand.project_brand](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_brand) | resource |
| [google_iap_client.iapoauth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_client) | resource |
| [google_project_service.project_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [null_resource.deploy_argo](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.iap](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.argoPwd](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.argotoken](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.iap-brand](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.nginx-ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.routerip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [github_ip_ranges.githubips](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/ip_ranges) | data source |
| [github_repository.autopilot_repo](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |
| [google_client_config.client](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_client_openid_userinfo.terraform_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_openid_userinfo) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [local_file.iap_oauth_client_details](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_cidr"></a> [access\_cidr](#input\_access\_cidr) | The accessible CIDR to use | `string` | `""` | no |
| <a name="input_git_details"></a> [git\_details](#input\_git\_details) | Details to use for the GitOps repo | <pre>object({<br>    git_token = string<br>    git_user  = string<br>    git_email = string<br>  })</pre> | n/a | yes |
| <a name="input_gitops_repo"></a> [gitops\_repo](#input\_gitops\_repo) | The name of the Autopilot repo | `string` | `"standard"` | no |
| <a name="input_k8s_allocation"></a> [k8s\_allocation](#input\_k8s\_allocation) | The CIDR range for Kubernetes. Leave default for GKE managed ranges | <pre>object({<br>    cluster_cidr = string,<br>    service_cidr = string<br>  })</pre> | <pre>{<br>  "cluster_cidr": "",<br>  "service_cidr": ""<br>}</pre> | no |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | The network CIDR to use | `string` | `""` | no |
| <a name="input_project"></a> [project](#input\_project) | The name of the project to use | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to use | `string` | `"us-central1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Project tags | `list` | `[]` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone to use | `string` | `"us-central1-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_allowed-ips"></a> [allowed-ips](#output\_allowed-ips) | Allowed IP CIDRs |
| <a name="output_argo-pwd"></a> [argo-pwd](#output\_argo-pwd) | Argo admin password |
| <a name="output_argo-token"></a> [argo-token](#output\_argo-token) | Argo user token |
| <a name="output_kubernetes-information"></a> [kubernetes-information](#output\_kubernetes-information) | Kubernetes server information |
| <a name="output_ngnix-ip"></a> [ngnix-ip](#output\_ngnix-ip) | External NGINX IP |
<!-- END_TF_DOCS -->
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
