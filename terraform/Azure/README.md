## Introduction

This repository contains Terraform code that will...

* Deploy a AKS environment (with a default firewall setup)
* Deploy a couple of facilitator Helm charts like Nginx, External DNS and External Secrets
* Deploy runtime Kubernetes secrets
* Deploy a standard Argo-suite via `autopilot`


Warning - This is an initial port only and may contain issues. Argo gets deployed to it fine, but has not been tested with the sample to ensure it is all working.

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
* `az`
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

* Currently, the installation only uses a standard Argo RBAC and server authentication module. SSO (via Dex) is not currently supported, but will be added time allowing
* This is an initial port only and has not been fully validated
* If the apply fails due to a null Argo token, then please just rerun the apply. This will refresh the token details and continue

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.85.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.3.1 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.47.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.85.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.2 |
| <a name="provider_github"></a> [github](#provider\_github) | 5.42.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.2 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_helmDeploy"></a> [helmDeploy](#module\_helmDeploy) | ../modules/helmDeploy | n/a |
| <a name="module_k8sDeploy"></a> [k8sDeploy](#module\_k8sDeploy) | ../modules/k8sDeploy | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.k8s_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.k8s_server_nodes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_log_analytics_solution.logsolution](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution) | resource |
| [azurerm_log_analytics_workspace.logworkspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_diagnostic_setting.diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_resource_group.resourceGroup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [null_resource.deploy_argo](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_integer.rndno](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [azuread_user.terraform_user](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) | data source |
| [azurerm_client_config.client](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [external_external.argoPwd](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.argotoken](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.nginx-ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.routerip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [github_ip_ranges.githubips](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/ip_ranges) | data source |
| [github_repository.autopilot_repo](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_cidr"></a> [access\_cidr](#input\_access\_cidr) | The accessible CIDR to use | `string` | `""` | no |
| <a name="input_git_details"></a> [git\_details](#input\_git\_details) | Details to use for the GitOps repo | <pre>object({<br>    git_token = string<br>    git_user  = string<br>    git_email = string<br>  })</pre> | n/a | yes |
| <a name="input_gitops_repo"></a> [gitops\_repo](#input\_gitops\_repo) | The name of the Autopilot repo | `string` | `"standard"` | no |
| <a name="input_k8s_allocation"></a> [k8s\_allocation](#input\_k8s\_allocation) | The CIDR range for Kubernetes. Leave default for GKE managed ranges | <pre>object({<br>    cluster_cidr = string,<br>    service_cidr = string<br>  })</pre> | <pre>{<br>  "cluster_cidr": "",<br>  "service_cidr": ""<br>}</pre> | no |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | The network CIDR to use | `string` | `""` | no |
| <a name="input_project"></a> [project](#input\_project) | The name of the project to use | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to use | `string` | `"ukwest"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Project tags | `map` | `{}` | no |

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
