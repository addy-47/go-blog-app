#define providers
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------------------------------------------------
# Modules for Infrastructure Provisioning
# -----------------------------------------------------------------------------

# 1. Enable required GCP APIs
module "gcp_project_setup" {
  source     = "./modules/gcp_project_setup"
  project_id = var.project_id
}

# Creating service account for Cloud Build
module "service_account" {
  source             = "./modules/service_accounts"
  project_id         = var.project_id
  service_account_id = var.service_account_id
  depends_on         = [module.gcp_project_setup] # Ensure APIs are enabled first
}

module "secrets" {
  source            = "./modules/secrets"
  project_id        = var.project_id
  github_repository = var.github_repository
  depends_on        = [module.service_accounts]
}

# Creating Compute Engine VM
module "compute_engine" {
  source                = "./modules/compute_engine"
  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  vm_name               = var.vm_name
  machine_type          = var.machine_type
  service_account_email = module.service_account.service_account_email
  ssh_public_key        = module.ssh_key.ssh_public_key
  depends_on            = [module.gcp_project_setup, module.artifact_registry, module.service_account, module.ssh_key]
}

# 4. Create Artifact Registry repository
module "artifact_registry" {
  source         = "./modules/artifact_registry"
  gcp_project_id = var.project_id
  gcp_region     = var.region
  gar_repository = var.artifact_repo_name
  depends_on     = [module.gcp_project_setup] # Ensure APIs are enabled first
}

module "firewall" {
  source     = "./modules/firewall"
  project_id = var.project_id
  depends_on = [module.gcp_project_setup]
}

module "budget" {
  source                = "./modules/budget"
  project_id            = var.project_id
  budget_amount         = var.budget_amount
  notification_channel  = var.gchat_webhook_url
}


