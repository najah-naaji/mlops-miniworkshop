# Create a GKE cluster 

resource "google_container_cluster" "gke-cluster" {
  name               = var.name
  location           = var.location
  description        = var.description   
  initial_node_count = var.node_count

  
  node_config {
    machine_type = var.node_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    service_account = var.sa_full_id

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    
    
  }
}
