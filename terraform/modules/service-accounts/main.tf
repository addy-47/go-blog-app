# This Service Account is for the CI/CD pipeline (GitHub Actions).
# It needs permissions to push to Artifact Registry and deploy to GKE.
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions CI/CD Service Account"
  project      = var.gcp_project_id
}

# Project-level permissions for GitHub Actions SA
resource "google_project_iam_member" "github_actions_permissions" {
  for_each = toset([
    "roles/container.developer", # For deploying to GKE
    "roles/logging.viewer",      # For viewing logs
    "roles/iam.serviceAccountUser", # To impersonate other SAs if needed
    "roles/artifactregistry.writer" # For pushing to Artifact Registry
  ])
  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# This Service Account is for the application workloads (frontend, backend, etc.) running in GKE.
# It needs permissions to write logs and metrics to Google Cloud's operations suite.
resource "google_service_account" "app_workload_sa" {
  account_id   = "app-workload-sa"
  display_name = "App Workload Service Account"
  project      = var.gcp_project_id
}

# Project-level permissions for App Workload SA to write logs and metrics
resource "google_project_iam_member" "app_workload_permissions" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])
  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.app_workload_sa.email}"
}

# This Service Account is for the database workload running in GKE.
# It needs permissions to write logs.
resource "google_service_account" "database_sa" {
  account_id   = "database-sa"
  display_name = "Database Service Account"
  project      = var.gcp_project_id
}

# Project-level permissions for Database SA to write logs
resource "google_project_iam_member" "database_permissions" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.database_sa.email}"
}

# This binding connects the GCP 'app_workload_sa' to the Kubernetes service account
# that will be used by your application pods in the 'ci-cd' namespace.
resource "google_service_account_iam_member" "app_workload_k8s_sa_policy" {
  service_account_id = google_service_account.app_workload_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[ci-cd/app-workload-sa]"
}

# This binding connects the GCP 'database_sa' to the Kubernetes service account
# that will be used by your database pod in the 'ci-cd' namespace.
resource "google_service_account_iam_member" "database_k8s_sa_policy" {
  service_account_id = google_service_account.database_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[ci-cd/database-sa]"
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

output "github_actions_sa_email" { value = google_service_account.github_actions_sa.email }
output "app_workload_sa_email" { value = google_service_account.app_workload_sa.email }
output "database_sa_email" { value = google_service_account.database_sa.email }