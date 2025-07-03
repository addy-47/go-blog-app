#define providers
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region # Default region for resources
}

# Data source to get the access token for Kubernetes provider
data "google_client_config" "default" {}

# Kubernetes Provider configuration
provider "kubernetes" {
  host                   = "https://${module.gke_cluster.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke_cluster.cluster_ca_certificate)
}

# -----------------------------------------------------------------------------
# Modules for Infrastructure Provisioning
# -----------------------------------------------------------------------------

# 1. Enable required GCP APIs
module "gcp_project_setup" {
  source         = "./modules/gcp-project-setup"
  gcp_project_id = var.gcp_project_id
}

# 2. Create GCP Service Accounts and their project-level IAM bindings
module "service_accounts" {
  source         = "./modules/service-accounts"
  gcp_project_id = var.gcp_project_id
  depends_on     = [module.gcp_project_setup] # Ensure APIs are enabled first
}

# 3. Create GKE Cluster
module "gke_cluster" {
  source           = "./modules/gke-cluster"
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  gke_cluster_name = var.gke_cluster_name
  depends_on       = [module.gcp_project_setup] # Ensure APIs are enabled first
}

# 4. Create Artifact Registry repository
module "artifact_registry" {
  source         = "./modules/artifact-registry"
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gar_repository = var.gar_repository
  depends_on     = [module.gcp_project_setup] # Ensure APIs are enabled first
}

# 5. Setup Workload Identity for GitHub Actions
module "workload_identity" {
  source                  = "./modules/workload-identity"
  gcp_project_id          = var.gcp_project_id
  github_repo             = var.github_repo
  github_actions_sa_email = module.service_accounts.github_actions_sa_email
  depends_on              = [module.gcp_project_setup] # Ensure APIs are enabled first
}

# 6. Provision Kubernetes Namespaces for your services
module "ci-cd_namespace" {
  source     = "./modules/gke-namespace"
  name       = "ci-cd"
  depends_on = [module.gke_cluster] # Ensure cluster is ready
}

# 7. Example: Provision a Cloud SQL instance for your database service
module "cloud_sql_instance" {
  source         = "./modules/cloud-sql"
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  database_name  = "blog-db"                  # Example database name
  depends_on     = [module.gcp_project_setup] # Ensure APIs are enabled first
}

# 8. Example: Provision a Secret Manager secret for your application
module "app_secret" {
  source                = "./modules/secret-manager"
  gcp_project_id        = var.gcp_project_id
  secret_name           = "my-app-secret" # Example secret name
  app_workload_sa_email = module.service_accounts.app_workload_sa_email
  depends_on            = [module.gcp_project_setup] # Ensure APIs are enabled first
}