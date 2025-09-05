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

variable "service_account_id" {
  description = "ID for the Cloud Build service account"
  type        = string
  default     = "cloudbuild-sa"
}

variable "github_repository" {
  description = "GitHub repository name (e.g., owner/repo)"
  type        = string
}

variable "billing_account_id" {
  description = "GCP Billing Account ID (e.g., 012345-6789AB-CDEF01)"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 2
}

variable "gchat_space_id" {
  description = "Google Chat space ID (e.g., spaces/AAQALXamGZk)"
  type        = string
}