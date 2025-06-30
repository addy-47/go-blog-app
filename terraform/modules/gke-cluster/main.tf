resource "google_container_cluster" "gke_cluster" {
  name                     = var.gke_cluster_name
  location                 = var.gcp_region
  initial_node_count       = 1
  deletion_protection      = false
  enable_autopilot         = true

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the GKE cluster."
  type        = string
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
}

output "cluster_endpoint" { value = google_container_cluster.gke_cluster.endpoint }
output "cluster_ca_certificate" { value = google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate }
output "cluster_name" { value = google_container_cluster.gke_cluster.name }