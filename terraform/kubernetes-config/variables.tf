variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "cluster_name" {
  type = string
}

variable "organization" {
  description = "organization"
  type        = string
}
variable "repository_name" {
  description = "repository name"
  type        = string
}

variable "repository_visibility" {
  description = "repository visibility"
  default     = "private"
  type        = string
}
variable "branch" {
  description = "branch"
  type        = string
  default     = "main"
}

variable "flux_namespace" {
  type        = string
  default     = "flux-system"
  description = "the flux namespace"
}

variable "target_path" {
  type        = string
  default     = "l15"
  description = "Relative path to the Git repository root where the sync manifests are committed."
}

variable "github_owner" {
  description = "github owner"
  type        = string
}

variable "github_deploy_key_title" {
  type        = string
  description = "Name of github deploy key"
}