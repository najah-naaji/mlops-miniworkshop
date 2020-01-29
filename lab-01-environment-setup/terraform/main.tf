
terraform {
  required_version = ">= 0.12"
}

# Configure GCP provider
provider "google" {
    project      = var.project_id
}

# Enable cloud services and configure service accounts: 
module "service_accounts" {
    source    = "./modules/service_accounts"
    kfp_sa_id = var.kfp_sa_id
    cluster_sa_id  = var.cluster_sa_id
}

# Configure GKE cluster with Kubeflow Pipelines
module "kfp_cluster" {
    source       = "./modules/kfp_cluster"
    location     = var.cluster_location
    cluster_name = var.cluster_name
    sa_email     = module.service_accounts.cluster_sa_email
    kfp_version  = var.kfp_version
    kfp_sa_key   = module.service_accounts.kfp_sa_key
}

# Create GCS bucket for pipeline artifacts
resource "google_storage_bucket" "artifacts-store" {
  name          = var.bucket_name
  storage_class = "MULTI_REGIONAL"
  force_destroy = true
}


