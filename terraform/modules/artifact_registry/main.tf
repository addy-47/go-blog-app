resource "google_artifact_registry_repository" "gar_repo" {
  location      = var.gcp_region
  repository_id = var.gar_repository
  format        = "DOCKER"
  description   = "Artifact Registry repository for Docker images"
  project       = var.gcp_project_id
}

variable "gcp_project_id" { type = string }
variable "gcp_region" { type = string }
variable "gar_repository" { type = string }


output "repository_name" {
  description = "The name of the Artifact Registry repository."
  value       = google_artifact_registry_repository.gar_repo.name
}