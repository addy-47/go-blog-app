resource "google_secret_manager_secret" "main" {
  secret_id = var.secret_name
  project   = var.gcp_project_id
    replication {
        auto {
        }
    }
}

# Grant the app service account permission to access this secret
resource "google_secret_manager_secret_iam_member" "app_access" {
  secret_id = google_secret_manager_secret.main.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.app_workload_sa_email}"
  project   = var.gcp_project_id
}

variable "gcp_project_id" { type = string }
variable "secret_name" {
  description = "The ID of the secret to create."
  type        = string
}
variable "app_workload_sa_email" {
  description = "The email of the App Workload Service Account to grant access to the secret."
  type        = string
}

output "secret_id" { value = google_secret_manager_secret.main.secret_id }