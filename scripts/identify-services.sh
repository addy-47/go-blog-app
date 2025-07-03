#!/bin/bash
set -euo pipefail

# Script to identify which services need to be processed
# Usage: ./identify-services.sh <services_config> <namespace> <before_commit> <current_commit>

SERVICES_CONFIG="$1"
NAMESPACE="$2"
BEFORE_COMMIT="$3"
CURRENT_COMMIT="$4"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to get changed services
get_changed_services() {
    local changed_services=""
    
    if [ "$BEFORE_COMMIT" = "0000000000000000000000000000000000000000" ]; then
        log "First push to branch, all services will be processed."
        changed_services=$(echo "$SERVICES_CONFIG" | grep -v -e '^$' -e '^\s*#' | cut -d: -f1 | tr '\n' ' ')
    else
        log "Getting changed files between $BEFORE_COMMIT and $CURRENT_COMMIT"
        local changed_files
        changed_files=$(git diff --name-only "$BEFORE_COMMIT" "$CURRENT_COMMIT")
        
        while IFS=: read -r workload dir; do
            [[ -z "$workload" || "$workload" == \#* ]] && continue
            if echo "$changed_files" | grep -q -E "^${dir}/"; then
                log "Changes detected in '$dir' for workload '$workload'"
                changed_services="$changed_services $workload"
            fi
        done <<< "$SERVICES_CONFIG"
    fi
    
    echo "$changed_services"
}

# Function to get missing services (not deployed)
get_missing_services() {
    local missing_services=""
    
    log "Checking for missing deployments in namespace '$NAMESPACE'..."
    
    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log "Namespace '$NAMESPACE' does not exist. All services will be considered missing."
        missing_services=$(echo "$SERVICES_CONFIG" | grep -v -e '^$' -e '^\s*#' | cut -d: -f1 | tr '\n' ' ')
    else
        local deployed_services
        deployed_services=$(kubectl get deployment -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
        log "Currently deployed services: $deployed_services"
        
        while IFS=: read -r workload dir; do
            [[ -z "$workload" || "$workload" == \#* ]] && continue
            if ! echo "$deployed_services" | grep -q -w "$workload"; then
                log "Service '$workload' is not deployed."
                missing_services="$missing_services $workload"
            fi
        done <<< "$SERVICES_CONFIG"
    fi
    
    echo "$missing_services"
}

# Main logic
main() {
    log "Starting service identification process..."
    
    # Get changed services
    local changed_services
    changed_services=$(get_changed_services)
    log "Changed services: $changed_services"
    
    # Get missing services
    local missing_services
    missing_services=$(get_missing_services)
    log "Missing services: $missing_services"
    
    # Combine and create unique list
    local services_to_process
    services_to_process=$(echo "$changed_services $missing_services" | xargs -n1 | sort -u | xargs)
    log "Services to process: $services_to_process"
    
    # Output for GitHub Actions
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "services=${services_to_process}" >> "$GITHUB_OUTPUT"
    fi
    
    # Also output to stdout for direct usage
    echo "$services_to_process"
}

# Validate inputs
if [ $# -ne 4 ]; then
    echo "Usage: $0 <services_config> <namespace> <before_commit> <current_commit>" >&2
    exit 1
fi

# Run main function
main