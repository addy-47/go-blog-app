variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "artifact_repo_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "blog-app"
}

variable "vm_name" {
  description = "Name of the Compute Engine VM"
  type        = string
  default     = "blog-vm"
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-medium"
}

variable "secret_id" {
  description = "Secret ID for GitHub SSH key in Secret Manager"
  type        = string
  default     = "github-ssh-key"
}

variable "github_ssh_key" {
  description = "GitHub SSH private key for repository access"
  type        = string
  sensitive   = true
}

variable "service_account_id" {
  description = "ID for the Cloud Build service account"
  type        = string
  default     = "cloudbuild-sa"
}