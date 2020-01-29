variable "location" {
    description = "The location the GKE cluster"
}

variable "cluster_name" {
    description = "The name of the GKE cluster"
}

variable "description" {
    description = "The cluster's description"
    default = "KFP cluster"
}

variable "node_count" {
    description = "The cluster's node count"
    default     = 3
}

variable "sa_email" {
    description = "The email account of the GKE service account"
}

variable "kfp_sa_key" {
    description = "The KFP service account key"
}

