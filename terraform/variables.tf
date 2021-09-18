variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

resource "google_service_account" "main" {
  account_id = "${var.cluster_name}-gke"
  display_name = "GKE Cluster Service Account"
}

# GKE cluster
resource "google_container_cluster" "main" {
  name     = "${var.cluster_name}"
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 3

  node_config {
    service_account = google_service_account.main.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.main.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.main.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.cluster_name
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.cluster_name}"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

variable "github_token" {
  description = "token for github"
  type        = string
}

variable "github_owner" {
  description = "github owner"
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

variable "organization" {
  description = "organization"
  type        = string
}

variable "branch" {
  description = "branch"
  type        = string
  default     = "main"
}

variable "target_path" {
  type        = string
  default     = "l15"
  description = "Relative path to the Git repository root where the sync manifests are committed."
}

variable "flux_namespace" {
  type        = string
  default     = "flux-system"
  description = "the flux namespace"
}

variable "use_private_endpoint" {
  type        = bool
  description = "Connect on the private GKE cluster endpoint"
  default     = false
}

variable "github_deploy_key_title" {
  type        = string
  description = "Name of github deploy key"
}
