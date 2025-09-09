resource "google_compute_instance" "vm" {
  project      = var.project_id
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/vm-startup.sh")

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  tags = ["http-server", "ssh"]
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "vm_name" {
  description = "Name of the Compute Engine VM"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the VM"
  type        = string
}

output "vm_name" { value = google_compute_instance.vm.name }

output "vm_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}