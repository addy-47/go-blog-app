#!/bin/bash
set -euo pipefail

# Script to deploy services to GKE
# Usage: ./deploy-to-gke.sh <services_config> <services_to_process> <image_tag> <registry_path> <namespace> <k8s_dir>

SERVICES_CONFIG="$1"
SERVICES_TO_PROCESS="$2"
IMAGE_TAG="$3"
REGISTRY_PATH="$4"
NAMESPACE="$5"
K8S_DIR="$6"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to ensure namespace exists
ensure_namespace() {
    local namespace="$1"
    
    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        log "Creating namespace: $namespace"
        kubectl create namespace "$namespace"
    else
        log "Namespace $namespace already exists"
    fi
}

# Function to validate k8s directory
validate_k8s_directory() {
    local workload="$1"
    local k8s_workload_dir="$K8S_DIR/$workload"
    
    if [ ! -d "$k8s_workload_dir" ]; then
        log "WARNING: k8s directory not found at $k8s_workload_dir for workload '$workload'"
        return 1
    fi
    
    log "k8s directory validated at $k8s_workload_dir"
    return 0
}

# Function to deploy a single service
deploy_service() {
    local workload="$1"
    local image_path="$2"
    local k8s_workload_dir="$K8S_DIR/$workload"
    
    log "--- Deploying workload '$workload' ---"
    
    # Validate k8s directory
    if ! validate_k8s_directory "$workload"; then
        log "ERROR: Skipping deployment for $workload due to missing k8s directory"
        return 1
    fi
    
    local deployment_file="$k8s_workload_dir/deployment.yaml"
    
    # Handle primary workload manifest (deployment, daemonset, etc.) with image update
    if [ -f "$deployment_file" ]; then
        local kind
        kind=$(grep '^kind:' "$deployment_file" | awk '{print $2}')
        log "Applying $kind with updated image..."

        if ! kubectl set image -f "$deployment_file" "${workload}=${image_path}" --local -o yaml | kubectl apply -n "$NAMESPACE" -f -; then
            log "ERROR: Failed to apply $kind for $workload"
            return 1
        fi
        log "✓ $kind applied for $workload"
    else
        log "WARNING: deployment.yaml not found for $workload at $deployment_file"
    fi
    
    # Apply other manifests (services, ingresses, etc.)
    local other_manifests
    other_manifests=$(find "$k8s_workload_dir" -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" \) -not -name "deployment.yaml" 2>/dev/null || echo "")
    
    if [ -n "$other_manifests" ]; then
        while IFS= read -r manifest; do
            log "Applying manifest: $manifest"
            if ! kubectl apply -n "$NAMESPACE" -f "$manifest"; then
                log "ERROR: Failed to apply manifest $manifest"
                return 1
            fi
        done <<< "$other_manifests"
    else
        log "No additional manifests found for $workload"
    fi
    
    # Wait for the primary workload to be ready
    if [ -f "$deployment_file" ]; then
        local kind
        kind=$(grep '^kind:' "$deployment_file" | awk '{print $2}')
        local kind_lower
        kind_lower=$(echo "$kind" | tr '[:upper:]' '[:lower:]')
        log "Waiting for $kind_lower $workload to be ready..."
        if ! kubectl rollout status "$kind_lower/$workload" -n "$NAMESPACE" --timeout=300s; then
            log "ERROR: $kind $workload failed to become ready"
            return 1
        fi
        log "✓ $kind $workload is ready"
    fi
    
    return 0
}

# Function to check if service should be processed
should_process_service() {
    local workload="$1"
    echo "$SERVICES_TO_PROCESS" | grep -q -w "$workload"
}

# Main logic
main() {
    log "Starting deployment process..."
    log "Services to process: $SERVICES_TO_PROCESS"
    log "Image tag: $IMAGE_TAG"
    log "Registry path: $REGISTRY_PATH"
    log "Namespace: $NAMESPACE"
    log "K8s directory: $K8S_DIR"
    
    if [ -z "$SERVICES_TO_PROCESS" ]; then
        log "No services to process. Exiting."
        exit 0
    fi
    
    # Ensure namespace exists
    ensure_namespace "$NAMESPACE"
    
    local failed_deployments=()
    local successful_deployments=()
    
    while IFS=: read -r workload dir; do
        [[ -z "$workload" || "$workload" == \#* ]] && continue
        
        if should_process_service "$workload"; then
            local image_path="$REGISTRY_PATH/$workload:$IMAGE_TAG"
            
            if deploy_service "$workload" "$image_path"; then
                successful_deployments+=("$workload")
                log "✓ Successfully deployed $workload"
            else
                failed_deployments+=("$workload")
                log "✗ Failed to deploy $workload"
            fi
        fi
    done <<< "$SERVICES_CONFIG"
    
    # Report results
    log "Deployment summary:"
    log "Successful: ${successful_deployments[*]}"
    log "Failed: ${failed_deployments[*]}"
    
    # Exit with error if any deployments failed
    if [ ${#failed_deployments[@]} -gt 0 ]; then
        log "ERROR: Some deployments failed. Exiting with error."
        exit 1
    fi
    
    log "All deployments completed successfully!"
}

# Validate inputs
if [ $# -ne 6 ]; then
    echo "Usage: $0 <services_config> <services_to_process> <image_tag> <registry_path> <namespace> <k8s_dir>" >&2
    exit 1
fi

# Run main function
main