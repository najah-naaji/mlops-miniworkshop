

data "google_project" "project" {}
data "google_client_config" "default" {}


# Create a GKE cluster with a default node pool and install KFP
resource "google_container_cluster" "kfp_cluster" {
  name               = var.cluster_name
  location           = var.location
  description        = var.description

  initial_node_count = var.node_count

  node_config {
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    service_account = var.sa_email

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

