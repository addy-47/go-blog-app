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

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e -x

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install dependencies
    apt-get install -y -qq curl uidmap

    # Install Docker using the official convenience script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    # Install the latest Docker Compose
    DOCKER_COMPOSE_VERSION="v2.24.7"
    curl -L "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Create a symlink for easy access
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    # Add the current user to docker group (this will be the service account user)
    USER_NAME=$(whoami)
    usermod -aG docker $USER_NAME

    # Alternatively, if you want to allow any user to run docker without sudo:
    # chmod 666 /var/run/docker.sock

    # Configure Docker to start on boot
    systemctl enable docker
    systemctl start docker

    # Configure gcloud docker credential helper for the VM's service account
    gcloud auth configure-docker $${var.region}-docker.pkg.dev

    # Create project directory and set permissions
    mkdir -p /home/$USER_NAME/go-blog-app
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/go-blog-app
  EOF

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