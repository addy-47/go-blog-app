resource "google_secret_manager_secret" "ssh_private_key" {
  project   = var.project_id
  secret_id = var.secret_name
  replication {
    auto {}
  }
}

output "ssh_private_key_id" {
  value = google_secret_manager_secret.ssh_private_key.secret_id
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "secret_name" {
  description = "The name of the secret to create for the SSH key."
  type        = string
  default     = "go-blog-app-ssh-private-key"
}