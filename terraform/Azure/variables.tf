variable "project" {
  type        = string
  description = "The name of the project to use"
}

variable "region" {
  type        = string
  default     = "ukwest"
  description = "The region to use"
}

variable "access_cidr" {
  type        = string
  default     = ""
  nullable    = true
  description = "The accessible CIDR to use"
}

variable "network_cidr" {
  type        = string
  default     = ""
  description = "The network CIDR to use"
}

variable "k8s_allocation" {
  type = object({
    cluster_cidr = string,
    service_cidr = string
  })
  description = "The CIDR range for Kubernetes. Leave default for GKE managed ranges"
  default = {
    service_cidr = "",
    cluster_cidr = ""
  }
}

variable "gitops_repo" {
  type        = string
  default     = "standard"
  description = "The name of the Autopilot repo"
}

variable "git_details" {
  type = object({
    git_token = string
    git_user  = string
    git_email = string
  })
  description = "Details to use for the GitOps repo"
  sensitive   = true
}

variable "tags" {
  default = {
  }
  description = "Project tags"
}
