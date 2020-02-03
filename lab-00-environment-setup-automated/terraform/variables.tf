variable "project_id" {
    description = "The GCP project ID"
    type        = string
}

variable "zone" {
    description = "The zone for the GKE cluster"
}

variable "name_prefix" {
    description = "The name prefix to add to the resource names"
    type        = string
}

variable "cluster_node_count" {
    description = "The cluster's node count"
    default     = 2
}

variable "cluster_node_type" {
    description = "The cluster's node type"
    default     = "n1-standard-8"
}

variable "cluster_node_description" {
    description = "The cluster's description"
    default     = "KFP GKE cluster"
}

variable "gke_service_account_roles" {
  description = "The roles to assign to the GKE service account"
  default = [
    "logging.logWriter",
    "monitoring.metricWriter", 
    "monitoring.viewer", 
    "stackdriver.resourceMetadata.writer",
    "storage.objectViewer" 
    ] 
}

variable "kfp_service_account_roles" {
  default = [    
    "storage.admin", 
    "bigquery.admin", 
    "automl.admin", 
    "automl.predictor",
    "ml.admin",
    "dataflow.admin",
    "cloudsql.admin"
  ]
}
