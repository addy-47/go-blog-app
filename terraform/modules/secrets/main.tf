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

resource "tls_private_key" "cloudbuild_ssh" {
    algorithm = "ED25519"
}

resource "google_secret_manager_secret" "cloudbuild_vm_ssh_key" {
    project   = var.project_id
    secret_id = "cloudbuild-vm-ssh-key"

    replication {
    auto {}
    }
}

resource "google_secret_manager_secret_version" "cloudbuild_vm_ssh_key_version" {
    secret      = google_secret_manager_secret.cloudbuild_vm_ssh_key.id
    secret_data = chomp(tls_private_key.cloudbuild_ssh.private_key_openssh)
}

resource "google_secret_manager_secret_iam_member" "cloudbuild_access" {
    project   = var.project_id
    secret_id = google_secret_manager_secret.cloudbuild_vm_ssh_key.secret_id
    role      = "roles/secretmanager.secretAccessor"
    member    = "serviceAccount:${var.service_account_email}"
}

variable "project_id" {
    description = "GCP Project ID"
    type        = string
}

variable "service_account_email" {
    description = "Service account email for accessing the secret"
    type        = string
}

output "ssh_public_key" {
    description = "Public key for Cloud Build SSH access to VM"
    value       = tls_private_key.cloudbuild_ssh.public_key_openssh
}