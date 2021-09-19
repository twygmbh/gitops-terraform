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


# Defer reading the cluster data until the GKE cluster exists.
data "google_container_cluster" "default" {
  name = var.cluster_name
  depends_on = [module.gke-cluster]
}

module "gke-cluster" {
  source        = "./gke-cluster"
  cluster_name  = var.cluster_name
  project_id    = var.project_id
  region        = var.region
  gke_num_nodes = var.gke_num_nodes
}