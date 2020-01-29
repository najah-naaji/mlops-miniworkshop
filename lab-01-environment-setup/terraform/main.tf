terraform {
  required_version = ">= 0.12"
  required_providers {
    google = "~> 2.0"
  }
}

# Provision MVP KFP infrastructure using reusable Terraform modules from
# github/jarokaz/terraform-gcp-kfp

provider "google" {
    project   = var.project_id 
}

# Create the GKE service account 
module "gke_service_account" {
  source                       = "./modules/service_account"
  service_account_id           = "${var.name_prefix}-gke-sa"
  service_account_display_name = "The GKE service account"
  service_account_roles        = var.gke_service_account_roles
}

# Create the KFP service account 
module "kfp_service_account" {
  source                       = "./modules/service_account"
  service_account_id           = "${var.name_prefix}-sa"
  service_account_display_name = "The KFP service account"
  service_account_roles        = var.kfp_service_account_roles
}


# Create the KFP GKE cluster
module "kfp_gke_cluster" {
  source                 = "./modules/gke"
  name                   = "${var.name_prefix}-cluster"
  location               = var.zone
  description            = var.cluster_node_description
  sa_full_id             = module.gke_service_account.service_account.email
  node_count             = var.cluster_node_count
  node_type              = var.cluster_node_type
}

# Create Cloud Storage bucket for artifact storage
resource "google_storage_bucket" "artifact_store" {
  name          = "${var.name_prefix}-artifact-store"
  force_destroy = true
}


