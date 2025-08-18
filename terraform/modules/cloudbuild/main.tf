resource "google_cloudbuild_trigger" "github_trigger" {
  project  = var.project_id
  name     = "go-blog-app-trigger"
  location = var.region

  github {
    owner = split("/", var.github_repo)[0]
    name  = split("/", var.github_repo)[1]
    push {
      branch = "^cloudbuild$"
    }
  }

  filename = "cloudbuild.yaml"
}

resource "google_cloudbuild_worker_pool" "worker_pool" {
  name     = "go-blog-app-worker-pool"
  project  = var.project_id
  location = var.region
  worker_config {
    disk_size_gb   = 100
    machine_type   = "e2-standard-4"
    no_external_ip = true
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "vm_ip" {
  type = string
}

variable "secret_id" {
  type = string
}