#!/bin/bash
set -euo pipefail

# Script to build and push Docker images
# Usage: ./build-and-push.sh <services_config> <services_to_process> <image_tag> <registry_path>

SERVICES_CONFIG="$1"
SERVICES_TO_PROCESS="$2"
IMAGE_TAG="$3"
REGISTRY_PATH="$4"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to validate dockerfile exists
validate_dockerfile() {
    local dir="$1"
    local dockerfile="$dir/Dockerfile"
    
    if [ ! -f "$dockerfile" ]; then
        log "ERROR: Dockerfile not found at $dockerfile"
        return 1
    fi
    
    log "Dockerfile validated at $dockerfile"
    return 0
}

# Function to build and push a single image
build_and_push_image() {
    local workload="$1"
    local dir="$2"
    local image_path="$3"
    
    log "--- Processing image for '$workload' ---"
    
    # Validate dockerfile exists
    if ! validate_dockerfile "$dir"; then
        log "ERROR: Skipping $workload due to missing Dockerfile"
        return 1
    fi
    
    # Build the image
    log "Building $image_path"
    if ! docker build -t "$image_path" -f "./$dir/Dockerfile" "./$dir"; then
        log "ERROR: Failed to build image for $workload"
        return 1
    fi
    
    # Push the image
    log "Pushing $image_path"
    if ! docker push "$image_path"; then
        log "ERROR: Failed to push image for $workload"
        return 1
    fi
    
    log "Successfully built and pushed $image_path"
    return 0
}

# Function to check if service should be processed
should_process_service() {
    local workload="$1"
    echo "$SERVICES_TO_PROCESS" | grep -q -w "$workload"
}

# Main logic
main() {
    log "Starting build and push process..."
    log "Services to process: $SERVICES_TO_PROCESS"
    log "Image tag: $IMAGE_TAG"
    log "Registry path: $REGISTRY_PATH"
    
    if [ -z "$SERVICES_TO_PROCESS" ]; then
        log "No services to process. Exiting."
        exit 0
    fi
    
    local failed_services=()
    local successful_services=()
    
    while IFS=: read -r workload dir; do
        [[ -z "$workload" || "$workload" == \#* ]] && continue
        
        if should_process_service "$workload"; then
            local image_path="$REGISTRY_PATH/$workload:$IMAGE_TAG"
            
            if build_and_push_image "$workload" "$dir" "$image_path"; then
                successful_services+=("$workload")
                log "✓ Successfully processed $workload"
            else
                failed_services+=("$workload")
                log "✗ Failed to process $workload"
            fi
        fi
    done <<< "$SERVICES_CONFIG"
    
    # Report results
    log "Build and push summary:"
    log "Successful: ${successful_services[*]}"
    log "Failed: ${failed_services[*]}"
    
    # Exit with error if any builds failed
    if [ ${#failed_services[@]} -gt 0 ]; then
        log "ERROR: Some builds failed. Exiting with error."
        exit 1
    fi
    
    log "All builds completed successfully!"
}

# Validate inputs
if [ $# -ne 4 ]; then
    echo "Usage: $0 <services_config> <services_to_process> <image_tag> <registry_path>" >&2
    exit 1
fi

# Run main function
main