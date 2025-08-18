resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_secret_manager_secret_version" "ssh_private_key_version" {
  secret      = "projects/${var.project_id}/secrets/${var.secret_id}"
  secret_data = tls_private_key.deploy_key.private_key_pem
}

resource "github_repository_deploy_key" "deploy_key" {
  title      = "go-blog-app-deploy-key"
  repository = split("/", var.github_repo)[1]
  key        = tls_private_key.deploy_key.public_key_openssh
  read_only  = false
}

resource "google_secret_manager_secret_iam_member" "cloudbuild_access" {
  project   = var.project_id
  secret_id = var.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account}"
}

output "ssh_public_key" {
  value = tls_private_key.deploy_key.public_key_openssh
}

variable "project_id" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "secret_id" {
  type = string
}

variable "service_account" {
  type = string
}