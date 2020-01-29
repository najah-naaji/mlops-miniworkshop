output "cluster_name" {
    value = google_container_cluster.kfp_cluster.name
}

output "cluster_endpoint" {
    value = google_container_cluster.kfp_cluster.endpoint
}


