variable "argocd_namespace" {
  type        = string
  description = "Argo namespace"
  default     = "argocd"
}

variable "argocd_token" {
  type        = string
  description = "Argo token"
  sensitive   = true
  nullable    = false
  validation {
    condition     = (var.argocd_token != "" || length(var.argocd_token) > 0)
    error_message = "The Argocd token must have a value. Try running the apply again."
  }
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

variable "iap_oauth_client_details" {
  type = object({
    clientID     = string
    clientSecret = string
  })
  default     = null
  description = "IAP auth2 details"
  sensitive   = true
}

variable "nginxip" {
  type        = string
  description = "NGINX LB IP"
  nullable    = false
  validation {
    condition     = (var.nginxip != "" || length(var.nginxip) > 0)
    error_message = "The LB IP must have a value. Try running the apply again."
  }
}
