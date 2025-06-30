output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = module.gke_cluster.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster."
  value       = module.gke_cluster.cluster_endpoint
  sensitive   = true
}

output "artifact_registry_repository_url" {
  description = "The URL of the Artifact Registry repository."
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.gar_repository}"
}

output "github_actions_sa_email" {
  description = "The email of the GitHub Actions Service Account."
  value       = module.service_accounts.github_actions_sa_email
}

output "app_workload_sa_email" {
  description = "The email of the App Workload Service Account."
  value       = module.service_accounts.app_workload_sa_email
}

output "database_sa_email" {
  description = "The email of the Database Service Account."
  value       = module.service_accounts.database_sa_email
}

output "workload_identity_provider" {
  description = "The full name of the Workload Identity Provider for GitHub Actions."
  value       = module.workload_identity.workload_identity_provider_name
  sensitive   = true
}
