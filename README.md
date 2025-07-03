# Go Microservices Blog Application on GKE

This project is a complete CI/CD pipeline for a microservices-based blog application written in Go. It is designed to be built and deployed automatically to a Google Kubernetes Engine (GKE) cluster using GitHub Actions.

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Directory Structure](#directory-structure)

## Architecture

The application consists of several containerized microservices that are deployed to a GKE cluster.

### Services

- **`frontend`**: The user-facing web interface. It communicates with the `backend` service.
- **`backend`**: The main API service that handles business logic and communicates with the database.
- **`worker`**: A background service for handling asynchronous tasks.
- **`logging-agent`**: A `DaemonSet` that runs on every node in the cluster to collect and forward logs.

### Technology Stack

- **Application**: Go
- **Containerization**: Docker
- **Orchestration**: Google Kubernetes Engine (GKE)
- **CI/CD**: GitHub Actions
- **Artifacts**: Google Artifact Registry (GAR)
- **Database**: Cloud SQL for PostgreSQL (or similar)
- **Authentication**: GKE Workload Identity for secure access to Google Cloud services.

## Prerequisites

Before you begin, ensure you have the following set up:

1.  **Google Cloud Project**: A GCP project with billing enabled.
2.  **Required APIs**: The following APIs must be enabled in your GCP project:
    -   Kubernetes Engine API
    -   Artifact Registry API
    -   Cloud SQL Admin API
    -   Identity and Access Management (IAM) API
3.  **Infrastructure**: The core infrastructure should be provisioned, likely using a tool like Terraform. This includes:
    -   A GKE cluster with Workload Identity enabled.
    -   A Google Artifact Registry (GAR) repository.
    -   A Cloud SQL instance.
    -   The necessary IAM Service Accounts (`app-workload-sa`, `database-sa`).
4.  **Local Tools**:
    -   `gcloud` CLI
    -   `kubectl`
    -   `docker`

## Configuration

To get the pipeline running, you need to configure your GitHub repository and Kubernetes manifests.

### 1. GitHub Repository Secrets

Navigate to your repository's **Settings > Secrets and variables > Actions** and add the following secrets:

-   `GCP_PROJECT_ID`: Your Google Cloud Project ID.
-   `GCP_WORKLOAD_IDENTITY_PROVIDER`: The full identifier of your Workload Identity Provider.
-   `GCP_SA_EMAIL`: The email address of the Google Service Account that GitHub Actions will use to authenticate.

### 2. Kubernetes Manifests

You will need to update some of the Kubernetes configuration files in the `k8s/` directory with values specific to your environment.

#### Database Configuration (`k8s/db-config.yaml`)

Update the `data` section with your Cloud SQL instance details:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-config
  namespace: ci-cd
data:
  DB_HOST: "YOUR_CLOUDSQL_PRIVATE_IP"
  DB_PORT: "5432"
  DB_NAME: "YOUR_DB_NAME"
  DB_USER: "YOUR_DB_USER"
```

#### Database Secret (`k8s/db-secret.yaml`)

The database password must be created as a secret in the cluster. For security, it's recommended to create this manually or have the pipeline manage it using a GitHub secret, rather than committing the password to the repository.

To create it manually, run:

```bash
kubectl create secret generic db-secret \
  --namespace=ci-cd \
  --from-literal=DB_PASSWORD='YOUR_SUPER_SECRET_PASSWORD'
```

## Deployment

The deployment process is fully automated via the GitHub Actions workflow defined in `.github/workflows/ci-cd.yaml`.

A deployment is triggered automatically on every `push` to the `ci-cd` branch.

The pipeline performs the following steps:

1.  **Authenticate to GCP**: Securely authenticates to Google Cloud using Workload Identity Federation.
2.  **Identify Changes**: The `identify-services.sh` script checks which service directories have changed since the last commit and which services are not yet deployed to the cluster.
3.  **Build and Push**: For each changed or missing service, the `build-and-push.sh` script builds a new Docker image, tags it with the commit SHA, and pushes it to your Google Artifact Registry repository.
4.  **Deploy to GKE**: The `deploy-to-gke.sh` script applies the Kubernetes manifests for each service. It dynamically updates the image tag in the `Deployment` or `DaemonSet` manifest and waits for the rollout to complete successfully.

## Directory Structure

The project is organized to separate service code, Kubernetes configuration, and CI/CD logic.

```
go-blog-app/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml        # Main GitHub Actions workflow
├── backend/                  # Source code for the backend service
│   └── Dockerfile
├── frontend/                 # Source code for the frontend service
│   └── Dockerfile
├── k8s/                      # All Kubernetes manifests
│   ├── backend/              # Manifests for the backend service
│   ├── frontend/             # Manifests for the frontend service
│   ├── ...
│   ├── db-config.yaml        # Shared database configuration
│   ├── db-secret.yaml        # Secret for the database password
│   └── rbac.yaml             # Shared RBAC roles and bindings
├── scripts/                  # CI/CD helper scripts
│   ├── build-and-push.sh
│   ├── deploy-to-gke.sh
│   └── identify-services.sh
└── README.md                 # This file
```