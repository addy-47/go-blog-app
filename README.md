# Go Microservices Blog Application on GKE

This project is a complete CI/CD pipeline for a microservices-based blog application written in Go. It is designed to be provisioned and deployed automatically to a Google Kubernetes Engine (GKE) cluster using Terraform and Google Cloud Build.

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Deployment](#deployment)
  - [Infrastructure Provisioning with Terraform](#infrastructure-provisioning-with-terraform)
  - [Terraform Modules](#terraform-modules)
  - [CI/CD with Cloud Build](#cicd-with-cloud-build)
- [Directory Structure](#directory-structure)

## Architecture

The application consists of several containerized microservices that are deployed to a GKE cluster. The entire infrastructure is provisioned using Terraform, and the CI/CD pipeline is managed by Google Cloud Build.

### Services

- **`frontend`**: The user-facing web interface. It communicates with the `backend` service.
- **`backend`**: The main API service that handles business logic and communicates with the database.
- **`worker`**: A background service for handling asynchronous tasks.
- **`logging-agent`**: A `DaemonSet` that runs on every node in the cluster to collect and forward logs.

### Technology Stack

- **Application**: Go
- **Containerization**: Docker
- **Orchestration**: Google Kubernetes Engine (GKE)
- **Infrastructure as Code**: Terraform
- **CI/CD**: Google Cloud Build
- **Artifacts**: Google Artifact Registry (GAR)
- **Database**: Cloud SQL for PostgreSQL (or similar)
- **Authentication**: GKE Workload Identity for secure access to Google Cloud services.

## Prerequisites

Before you begin, ensure you have the following set up:

1.  **Google Cloud Project**: A GCP project with billing enabled.
2.  **Local Tools**:
    -   `gcloud` CLI
    -   `kubectl`
    -   `docker`
    -   `terraform`

## Local Development

To run the application stack locally for development, you can use the provided Docker Compose configuration.

1.  **Build and Run:**
    ```bash
    docker-compose up --build
    ```

This will build the Docker images for the `frontend`, `backend`, and `worker` services and start them along with a PostgreSQL database.

## Deployment

The deployment process is managed by Terraform and Google Cloud Build.

### Infrastructure Provisioning with Terraform

The Terraform configuration in the `terraform/` directory provisions all the necessary cloud infrastructure.

To provision the infrastructure, navigate to the `terraform/` directory and run:

```bash
terraform init
terraform apply
```

You will be prompted to provide values for the variables defined in `variables.tf`, such as your GCP project ID and desired region.

### Terraform Modules

The infrastructure is organized into reusable Terraform modules for clarity and maintainability:

-   **`gcp_project_setup`**: Enables the necessary Google Cloud APIs required for the project, such as Compute Engine, Artifact Registry, Cloud Build, and Secret Manager.
-   **`service_accounts`**: Creates a dedicated IAM Service Account for Cloud Build. It grants this service account the specific roles it needs to build images, push to Artifact Registry, and deploy to GKE.
-   **`artifact_registry`**: Provisions a Google Artifact Registry repository. This repository is configured to store the Docker images for each microservice.
-   **`ssh_key`**: Generates an ED25519 SSH key pair. The public key is used to grant access to the GCE virtual machine, while the private key is securely stored in Google Secret Manager.
-   **`secret_manager`**: A general-purpose module for creating and managing secrets in Google Secret Manager. It's used by the `ssh_key` module to store the private key and grant the Cloud Build service account access to it.
-   **`compute_engine`**: Creates a Google Compute Engine virtual machine. A startup script on the VM installs Docker, clones the application repository using the SSH key, and prepares the environment.
-   **`firewall`**: Sets up firewall rules in your VPC to allow HTTP (port 80) and SSH (port 22) traffic to the Compute Engine instance, making it accessible for serving content and for maintenance.

### CI/CD with Cloud Build

The `cloudbuild.yaml` file defines the CI/CD pipeline that automates the build and deployment process. A build can be triggered manually from the command line:

```bash
gcloud builds submit --config cloudbuild.yaml .
```

The pipeline performs the following steps:

1.  **Build and Push**: For each service (`backend`, `frontend`, `worker`, `logging-agent`), Cloud Build builds a new Docker image, tags it with the current commit SHA, and pushes it to the Google Artifact Registry repository created by Terraform.
2.  **Deploy to GKE**: The `gke-deploy` step applies the Kubernetes manifests for each service to the GKE cluster, rolling out the new versions of the applications.

## Directory Structure

The project is organized to separate service code, infrastructure configuration, and CI/CD logic.

```
go-blog-app/
├── backend/                  # Source code for the backend service
│   └── Dockerfile
├── frontend/                 # Source code for the frontend service
│   └── Dockerfile
├── worker/                   # Source-code for the worker service
│   └── Dockerfile
├── logging-agent/            # Source code for the logging-agent service
│   └── Dockerfile
├── terraform/                # Terraform configuration for infrastructure
│   ├── main.tf
│   ├── variables.tf
│   └── modules/              # Reusable Terraform modules
│       ├── artifact_registry/
│       ├── compute_engine/
│       ├── firewall/
│       ├── gcp_project_setup/
│       ├── secret_manager/
│       ├── service_accounts/
│       └── ssh_key/
├── cloudbuild.yaml           # Google Cloud Build configuration
├── docker-compose.yaml       # Docker Compose for local development
└── README.md                 # This file
```

