resource "google_secret_manager_secret" "secret" {
  project   = var.project_id
  secret_id = var.secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_data
}

resource "google_secret_manager_secret_iam_member" "cloudbuild_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "secret_id" {
  description = "Secret ID for the secret"
  type        = string
}

variable "secret_data" {
  description = "Data to store in the secret"
  type        = string
  sensitive   = true
}

variable "service_account_email" {
  description = "Service account email for accessing the secret"
  type        = string
}

output "secret_id" { value = google_secret_manager_secret.secret.secret_id }