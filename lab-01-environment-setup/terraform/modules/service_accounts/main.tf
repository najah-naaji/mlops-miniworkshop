# Configure the KFP service account

resource "google_service_account" "kfp_sa" {
    account_id   = var.kfp_sa_id
    display_name = "KFP Service Account"
}

resource "google_project_iam_member" "kfp_sa_roles" {
  count   = length(var.kfp_sa_roles)
  role    = "roles/${var.kfp_sa_roles[count.index]}"
  member  = "serviceAccount:${google_service_account.kfp_sa.email}"
}

resource "google_service_account_key" "kfp_sa_key" {
    service_account_id = "${google_service_account.kfp_sa.name}"
}


# Configure the GKE cluster service account with the minimum necessary roles and permissions in order to run the GKE cluster

resource "google_service_account" "cluster_sa" {
    account_id   = var.cluster_sa_id
    display_name = "Least Priviledge Service Account"
}

resource "google_project_iam_member" "cluster_sa_roles" {
  count   = length(var.cluster_sa_roles)
  role    = "roles/${var.cluster_sa_roles[count.index]}"
  member  = "serviceAccount:${google_service_account.cluster_sa.email}"
}


# Grant Cloud Build access to google_service_account_key

data "google_project" "project" {}

resource "google_project_iam_member" "cloud-build-container-developer" {
    role    = "roles/container.developer"
    member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}