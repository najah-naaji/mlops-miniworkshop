output "name" {
    value = google_container_cluster.gke-cluster.name
}

output "cluster_endpoint" {
    value = google_container_cluster.gke-cluster.endpoint
}
