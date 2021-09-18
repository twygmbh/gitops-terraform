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

provider "flux" {}
