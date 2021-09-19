terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.80.0"
    }
    flux = {
      source = "fluxcd/flux"
      version = "0.3.1"
    }
    github = {
      source = "integrations/github"
      version = "4.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.11.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }

  backend "gcs" {
    bucket = "tf-state-gitops-terraform-a"
    prefix = "gitops-terraform"
  }
}

# Provider is configured using environment variables: GOOGLE_REGION, GOOGLE_PROJECT, GOOGLE_CREDENTIALS.
# This can be set statically, if preferred. See docs for details.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#full-reference
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Github
provider "github" {
  token        = var.github_token
  owner        = var.github_owner
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {
  depends_on = [module.gke-cluster]
}

# Defer reading the cluster data until the GKE cluster exists.
data "google_container_cluster" "default" {
  name = var.cluster_name
  depends_on = [module.gke-cluster]
}

module "gke_auth" {
  depends_on           = [module.gke-cluster]
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id           = var.project_id
  cluster_name         = var.cluster_name
  location             = var.region
  use_private_endpoint = false
}

provider "kubernetes" {
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  host                   = module.gke_auth.host
  token                  = module.gke_auth.token
}

provider "kubectl" {
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  host                   = module.gke_auth.host
  token                  = module.gke_auth.token
  load_config_file       = false
}

module "gke-cluster" {
  source        = "./gke-cluster"
  cluster_name  = var.cluster_name
  project_id    = var.project_id
  region        = var.region
  gke_num_nodes = var.gke_num_nodes
}

module "kubernetes-config" {
  depends_on                = [module.gke-cluster]
  source                    = "./kubernetes-config"
  project_id                = var.project_id
  region                    = var.region
  cluster_name              = var.cluster_name
  target_path               = var.target_path 
  organization              = var.organization
  github_owner              = var.github_owner
  repository_name           = var.repository_name
  repository_visibility     = var.repository_visibility
  branch                    = var.branch
  github_deploy_key_title   = var.github_deploy_key_title
}