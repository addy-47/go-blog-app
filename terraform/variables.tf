variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for resources."
  type        = string
  default     = "us-central1" # Example default, adjust as needed
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "blog-devops-cluster"
}

variable "gar_repository" {
  description = "The ID of the Artifact Registry repository."
  type        = string
  default     = "blog-devops-gar"
}

variable "github_repo" {
  description = "The GitHub repository (e.g., 'owner/repo') for Workload Identity."
  type        = string
  # Example: "addy-47/ci-cd-k8s" - Make sure to set this to your actual repo!
}