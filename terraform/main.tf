#define providers
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "github" {
  token = local.github_token
  owner = split("/", var.github_repository)[0]
}

data "google_project" "project" {}

# -----------------------------------------------------------------------------
# Modules for Infrastructure Provisioning
# -----------------------------------------------------------------------------

# 1. Enable required GCP APIs
module "gcp_apis" {
  source     = "./modules/gcp_apis"
  project_id = var.project_id
}

# Creating service account for Cloud Build
module "service_account" {
  source             = "./modules/service_accounts"
  project_id         = var.project_id
  service_account_id = var.service_account_id
  depends_on         = [module.gcp_apis]
}

# Creating Compute Engine VM
module "vm" {
  source                = "./modules/vm"
  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  vm_name               = var.vm_name
  machine_type          = var.machine_type
  service_account_email = module.service_account.service_account_email
  depends_on            = [module.service_account]
}

# 4. Create Artifact Registry repository
module "artifact_registry" {
  source         = "./modules/artifact_registry"
  gcp_project_id = var.project_id
  gcp_region     = var.region
  gar_repository = var.artifact_repo_name
  depends_on     = [module.gcp_apis]
}

# module "budget" {
#   source             = "./modules/budget"
#   project_id         = var.project_id
#   billing_account_id = var.billing_account_id
#   budget_amount      = var.budget_amount
#   gchat_space_id     = var.gchat_space_id
#   depends_on         = [module.gcp_apis]
# }