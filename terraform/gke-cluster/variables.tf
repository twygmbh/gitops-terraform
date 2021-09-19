variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "cluster_name" {
  type = string
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}