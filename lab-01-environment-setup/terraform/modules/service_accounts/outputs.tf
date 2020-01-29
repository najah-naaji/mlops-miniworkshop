output "kfp_sa_email" {
    value = google_service_account.kfp_sa.email
}

output "kfp_sa_name" {
    value = google_service_account.kfp_sa.name
}


output "kfp_sa_key" {
    value     = google_service_account_key.kfp_sa_key
    sensitive = true
}

output "cluster_sa_email" {
    value = google_service_account.cluster_sa.email
}

output "cluster_sa_name" {
    value = google_service_account.cluster_sa.name
}
