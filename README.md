# Go Microservices Blog Application on Google Cloud

This project is a complete CI/CD pipeline for a microservices-based blog application written in Go. It is designed to be provisioned and deployed automatically to a Google Compute Engine (GCE) virtual machine using Terraform and Google Cloud Build.

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Deployment](#deployment)
- [Infrastructure Provisioning with Terraform](#infrastructure-provisioning-with-terraform)
- [CI/CD with Cloud Build](#cicd-with-cloud-build)
- [Directory Structure](#directory-structure)

## Architecture

The application consists of several containerized microservices that are deployed to a single Google Compute Engine (GCE) VM. The entire infrastructure is provisioned using Terraform, and the CI/CD pipeline is managed by Google Cloud Build. Docker Compose is used on the VM to run the services.

### Services

- **`frontend`**: The user-facing web interface. It communicates with the `backend` service.
- **`backend`**: The main API service that handles business logic and communicates with the database.
- **`worker`**: A background service for handling asynchronous tasks.
- **`logging-agent`**: A sidecar service for collecting and forwarding logs.

### Technology Stack

- **Application**: Go
- **Containerization**: Docker
- **Orchestration**: Docker Compose on a GCE VM
- **Infrastructure as Code**: Terraform
- **CI/CD**: Google Cloud Build
- **Artifacts**: Google Artifact Registry (GAR)
- **Database**: PostgreSQL (running in a Docker container)
- **Authentication**: IAM Service Account for secure access to Google Cloud services.

## Prerequisites

Before you begin, ensure you have the following set up:

1.  **Google Cloud Project**: A GCP project with billing enabled.
2.  **Local Tools**:
    -   `gcloud`
    -   `docker`
    -   `terraform`

## Local Development

To run the application stack locally for development, you can use the provided Docker Compose configuration.

1.  **Set Environment Variables:**
    Before running, you need to set the `GAR_REGISTRY` and `TAG_NAME` environment variables, as the `docker-compose.yml` file expects them. For local development, you can use any value for the tag.
    ```bash
    export GAR_REGISTRY=local
    export TAG_NAME=latest
    # Build the images locally first if they don't exist
    docker build -t local/backend:latest ./backend
    docker build -t local/frontend:latest ./frontend
    # ... and so on for other services
    ```
2.  **Run with Docker Compose:**
    ```bash
    docker-compose up --build
    ```

This will start the `frontend`, `backend`, and `worker` services along with a PostgreSQL database.

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

### CI/CD with Cloud Build

The `cloudbuild.yaml` file defines the CI/CD pipeline that automates the build and deployment process. A build can be triggered manually from the command line:

```bash
gcloud builds submit --config cloudbuild.yaml .
```

The pipeline performs the following steps:

1.  **Detect Changes**: The pipeline first detects which services have changed in the latest commit and which services are not yet running on the target VM.
2.  **Build and Push**: For each new or changed service, Cloud Build builds a new Docker image, tags it with the current commit SHA, and pushes it to the Google Artifact Registry repository.
3.  **Deploy to GCE VM**: The pipeline copies an updated `docker-compose.yml` file to the VM and runs `docker-compose pull` and `docker-compose up` to pull the new images and restart the necessary services.

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
│       ├── gcp_apis/
│       ├── artifact_registry/
│       ├── service_accounts/
│       └── vm/
├── cloudbuild.yaml           # Google Cloud Build configuration
├── docker-compose.yaml       # Docker Compose for local development
└── README.md                 # This file
```
