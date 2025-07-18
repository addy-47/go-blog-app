resource "google_compute_firewall" "allow_ssh" {
    project     = var.project_id
    name        = "default-allow-ssh"
    network     = "default"
    description = "Allow SSH access to VMs with ssh tag"

    allow {
    protocol = "tcp"
    ports    = ["22"]
    }

    target_tags = ["ssh"]
    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_http" {
    project     = var.project_id
    name        = "default-allow-http"
    network     = "default"
    description = "Allow HTTP access to VMs with http tag"

    allow {
        protocol = "tcp"
        ports    = ["80"]
    }

    target_tags = ["http"]
    source_ranges = ["0.0.0.0/0"]
}

variable "project_id" {
    description = "The ID of the project in which the resource belongs."
    type        = string
}