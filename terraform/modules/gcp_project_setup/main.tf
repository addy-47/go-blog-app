resource "google_project_service" "services" {
  for_each = toset([
    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

output "enabled_services" {
  description = "List of enabled GCP services"
  value       = [for s in google_project_service.services : s.service]
}