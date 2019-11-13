terraform {
  required_version = ">= 0.12"
}

# Provision MVP KFP infrastructure using reusable Terraform modules from
# github/jarokaz/terraform-gcp-kfp

provider "google" {
    project   = var.project_id 
}

# Create the GKE service account 
module "gke_service_account" {
  source                       = "github.com/jarokaz/terraform-gcp-kfp/modules/service_account"
  service_account_id           = "${var.name_prefix}-gke-sa"
  service_account_display_name = "The GKE service account"
  service_account_roles        = var.gke_service_account_roles
}

# Create the KFP service account 
module "kfp_service_account" {
  source                       = "github.com/jarokaz/terraform-gcp-kfp/modules/service_account"
  service_account_id           = "${var.name_prefix}-sa"
  service_account_display_name = "The KFP service account"
  service_account_roles        = var.kfp_service_account_roles
}

# Create the VPC for the KFP cluster
module "kfp_gke_vpc" {
  source                 = "github.com/jarokaz/terraform-gcp-kfp/modules/vpc"
  region                 = var.region
  network_name           = "${var.name_prefix}-network"
  subnet_name            = "${var.name_prefix}-subnet"
}

# Create the KFP GKE cluster
module "kfp_gke_cluster" {
  source                 = "github.com/jarokaz/terraform-gcp-kfp/modules/gke"
  name                   = "${var.name_prefix}-cluster"
  location               = var.zone != "" ? var.zone : var.region
  description            = "KFP GKE cluster"
  sa_full_id             = module.gke_service_account.service_account.email
  network                = module.kfp_gke_vpc.network_name
  subnetwork             = module.kfp_gke_vpc.subnet_name
  node_count             = var.cluster_node_count
  node_type              = var.cluster_node_type
}

# Create the MySQL instance for ML Metadata
module "ml_metadata_mysql" {
  source  = "github.com/jarokaz/terraform-gcp-kfp//modules/mysql"
  region  = var.region
  name    = "${var.name_prefix}-metadata"
}

# Create Cloud Storage bucket for artifact storage
resource "google_storage_bucket" "artifact_store" {
  name          = "${var.name_prefix}-artifact-store"
  force_destroy = true
}

