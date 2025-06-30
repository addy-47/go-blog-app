resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "sqladmin.googleapis.com", # Added for Cloud SQL
  ])
  project                    = var.gcp_project_id
  service                    = each.key
  disable_dependent_services = true
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}