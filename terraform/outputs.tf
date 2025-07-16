output "artifact_registry_repository_url" {
  description = "The URL of the Artifact Registry repository."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_name}"
}

output "service_account_email" {
  description = "The email of the service account created for Cloud Build."
  value       = module.service_account.service_account_email
}

output "compute_engine_instance_name" {
  description = "The name of the Compute Engine VM instance."
  value       = module.compute_engine.vm_name
}

