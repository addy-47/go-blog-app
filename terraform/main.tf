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
  source         = "./modules/gcp_project_setup"
  project_id = var.project_id
}

# Creating service account for Cloud Build
module "service_account" {
  source             = "./modules/service_accounts"
  project_id         = var.project_id
  service_account_id = var.service_account_id
  depends_on         = [module.gcp_project_setup] # Ensure APIs are enabled first
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
  depends_on            = [module.gcp_project_setup, module.artifact_registry, module.service_account]
}

# 4. Create Artifact Registry repository
module "artifact_registry" {
  source         = "./modules/artifact_registry"
  gcp_project_id = var.project_id
  gcp_region     = var.region
  gar_repository = var.artifact_repo_name
  depends_on     = [module.gcp_project_setup] # Ensure APIs are enabled first
}


# Setting up Secret Manager for GitHub SSH key
module "secret_manager" {
  source                = "./modules/secret_manager"
  project_id            = var.project_id
  secret_id             = var.secret_id
  secret_data           = var.github_ssh_key
  service_account_email = module.service_account.service_account_email
  depends_on            = [module.gcp_project_setup, module.service_account]
}



