provider "google" {
  project = var.project_id
  region  = var.region
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
    service_account = google_service_account.main.email

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

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}


# data "flux_install" "main" {
#   target_path = var.target_path
# }

# data "flux_sync" "main" {
#   target_path = var.target_path
#   url         = "ssh://git@github.com/${var.organization}/${var.repository_name}.git"
#   branch      = var.branch
# }

# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [google_container_cluster.main]

#   create_duration = "30s"
# }

# module "gke_auth" {
#   depends_on           = [time_sleep.wait_30_seconds]
#   source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
#   project_id           = var.project_id
#   cluster_name         = google_container_cluster.main.name
#   location             = var.region
#   use_private_endpoint = false
# }

# provider "kubernetes" {
#   cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
#   host                   = module.gke_auth.host
#   token                  = module.gke_auth.token
# }

# provider "kubectl" {
#   cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
#   host                   = module.gke_auth.host
#   token                  = module.gke_auth.token
#   load_config_file       = false
# }

# resource "kubernetes_namespace" "flux_system" {
#   metadata {
#     name = var.flux_namespace
#   }

#   lifecycle {
#     ignore_changes = [
#       metadata[0].labels,
#     ]
#   }
# }

# data "kubectl_file_documents" "install" {
#   content = data.flux_install.main.content
# }

# data "kubectl_file_documents" "sync" {
#   content = data.flux_sync.main.content
# }

# locals {
#   install = [for v in data.kubectl_file_documents.install.documents : {
#     data : yamldecode(v)
#     content : v
#     }
#   ]
#   sync = [for v in data.kubectl_file_documents.sync.documents : {
#     data : yamldecode(v)
#     content : v
#     }
#   ]
# }

# resource "kubectl_manifest" "install" {
#   depends_on = [kubernetes_namespace.flux_system]
#   for_each   = { for v in local.install : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
#   yaml_body  = each.value
# }

# resource "kubectl_manifest" "sync" {
#   depends_on = [kubectl_manifest.install, kubernetes_namespace.flux_system]
#   for_each   = { for v in local.sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
#   yaml_body  = each.value
# }

# locals {
#   known_hosts = "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="
# }

# resource "tls_private_key" "github_deploy_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "kubernetes_secret" "main" {
#   depends_on = [kubectl_manifest.install]

#   metadata {
#     name      = data.flux_sync.main.secret
#     namespace = data.flux_sync.main.namespace
#   }

#   data = {
#     known_hosts    = local.known_hosts
#     identity       = tls_private_key.github_deploy_key.private_key_pem
#     "identity.pub" = tls_private_key.github_deploy_key.public_key_openssh
#   }
# }

# # Github
# provider "github" {
#   token        = var.github_token
#   owner        = var.github_owner
# }

# # To make sure the repository exists and the correct permissions are set.
# data "github_repository" "main" {
#   full_name = "${var.github_owner}/${var.repository_name}"
# }

# resource "github_repository_file" "install" {
#   repository          = data.github_repository.main.name
#   file                = data.flux_install.main.path
#   content             = data.flux_install.main.content
#   branch              = var.branch
#   overwrite_on_create = true
# }

# resource "github_repository_file" "sync" {
#   repository          = var.repository_name
#   file                = data.flux_sync.main.path
#   content             = data.flux_sync.main.content
#   branch              = var.branch
#   overwrite_on_create = true
# }

# resource "github_repository_file" "kustomize" {
#   repository          = var.repository_name
#   file                = data.flux_sync.main.kustomize_path
#   content             = data.flux_sync.main.kustomize_content
#   branch              = var.branch
#   overwrite_on_create = true
# }

# # For flux to fetch source
# resource "github_repository_deploy_key" "flux" {
#   title      = var.github_deploy_key_title
#   repository = data.github_repository.main.name
#   key        = tls_private_key.github_deploy_key.public_key_openssh
#   read_only  = true
# }