resource "google_service_account" "cloudbuild_sa" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Cloud Build Service Account for go-blog-app"
}

resource "google_project_iam_member" "cloudbuild_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/compute.instanceAdmin.v1",
    "roles/secretmanager.secretAccessor",
    "roles/cloudbuild.builds.builder",
    "roles/storage.objectCreator"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account_id" {
  description = "ID for the service account"
  type        = string
  default     = "cloudbuild-sa"
}

output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.cloudbuild_sa.email
}