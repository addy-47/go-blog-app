resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions WIP"
  description               = "Workload Identity Pool for GitHub Actions to access GCP resources"
  project                   = var.gcp_project_id
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "Provider for GitHub Actions to authenticate with GCP using OIDC"
  project                            = var.gcp_project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "assertion.repository == '${var.github_repo}' && assertion.ref.startsWith('refs/heads/')"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# This policy allows identities from the GitHub provider (that match the repository condition)
# to impersonate the 'github_actions_sa' Google Cloud Service Account.
resource "google_service_account_iam_member" "github_actions_sa_policy" {
  service_account_id = "projects/${var.gcp_project_id}/serviceAccounts/${var.github_actions_sa_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

variable "gcp_project_id" { type = string }
variable "github_repo" { type = string }
variable "github_actions_sa_email" { type = string }

output "workload_identity_provider_name" {
  description = "The full name of the Workload Identity Provider for GitHub Actions."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

