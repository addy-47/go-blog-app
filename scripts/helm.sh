#!/bin/bash
set -e  # Exit on any error

echo "🚀 Starting Helm deployment process..."

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ Error: $1 is not installed"
        exit 1
    fi
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}  # Default timeout of 300 seconds (5 minutes)
    local start_time=$(date +%s)
    
    echo "⏳ Waiting for pods to be ready in namespace $namespace..."
    while true; do
        if [ $(($(date +%s) - start_time)) -gt "$timeout" ]; then
            echo "❌ Timeout waiting for pods to be ready"
            return 1
        fi
        
        if ! kubectl get pods -n "$namespace" 2>/dev/null | grep -q "Running"; then
            echo "⏳ Pods are not ready yet..."
            sleep 5
            continue
        fi
        
        if ! kubectl get pods -n "$namespace" 2>/dev/null | grep -qE "ContainerCreating|Pending"; then
            if ! kubectl get pods -n "$namespace" 2>/dev/null | grep -q "Error"; then
                echo "✅ All pods are ready!"
                return 0
            fi
        fi
        
        sleep 5
    done
}

# Check required commands
check_command kubectl
check_command helm

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Cannot connect to Kubernetes cluster"
    exit 1
fi

# Check if Istio is installed
if ! kubectl get namespace istio-system &>/dev/null; then
    echo "❌ Error: Istio is not installed. Please install Istio first."
    exit 1
fi

# Verify Chart existence
if [ ! -d "./charts/blog-platform" ]; then
    echo "❌ Error: blog-platform chart not found in ./charts directory"
    exit 1
fi

# Apply CRD first
echo "🔧 Applying BlogPost CRD..."
if [ ! -f "crds/blogpost-crd.yaml" ]; then
    echo "❌ Error: BlogPost CRD file not found"
    exit 1
fi

if ! kubectl apply -f crds/blogpost-crd.yaml; then
    echo "❌ Error: Failed to apply CRD"
    exit 1
fi

# Deploy Helm chart
echo "📦 Installing blog-platform Helm chart..."
if ! helm lint ./charts/blog-platform; then
    echo "❌ Error: Helm chart validation failed"
    exit 1
fi

echo "🔍 Checking Kubernetes cluster status..."
kubectl get nodes

echo "⏳ Installing Helm chart (this may take a few minutes)..."
if ! helm install blog-platform ./charts/blog-platform \
    --timeout 10m \
    --set frontend.image=frontend:latest \
    --set backend.image=backend:latest \
    --set worker.image=worker:latest \
    --set loggingAgent.image=logging-agent:latest; then

    if helm list | grep -q "blog-platform"; then
        # If the release already exists, attempt to upgrade
        echo "⚠️ Warning: Helm release 'blog-platform' already exists. Attempting to upgrade..."
        if ! helm upgrade blog-platform ./charts/blog-platform \
            --timeout 10m \
            --set frontend.image=frontend:latest \
            --set backend.image=backend:latest \
            --set worker.image=worker:latest \
            --set loggingAgent.image=logging-agent:latest; then
            echo "❌ Error: Failed to upgrade Helm chart"
            exit 1
        fi
    else
        echo "❌ Error: Failed to install Helm chart"
        exit 1
    fi
    
    echo "❌ Error: Failed to install Helm chart"
    echo "📋 Checking pod status..."
    kubectl get pods
    echo "📋 Checking persistent volumes..."
    kubectl get pv,pvc
    echo "📋 Checking services..."
    kubectl get services
    echo "📋 Checking events..."
    kubectl get events --sort-by='.metadata.creationTimestamp'
    exit 1
fi

# Apply Istio configurations
echo "🌐 Applying Istio configurations..."
if [ ! -f "k8s-security/istio.yaml" ]; then
    echo "❌ Error: Istio configuration file not found"
    exit 1
fi

if ! kubectl apply -f k8s-security/istio.yaml; then
    echo "❌ Error: Failed to apply Istio configurations"
    exit 1
fi

# Wait for deployments to be ready
echo "🔍 Verifying deployments..."
if ! wait_for_pods "default" 300; then
    echo "❌ Error: Deployment verification failed"
    echo "📋 Current pod status:"
    kubectl get pods
    exit 1
fi

# Show resource status
echo "📋 Deployment Status:"
echo "--------------------"
echo "🔷 Pods:"
kubectl get pods
echo "--------------------"
echo "🔷 Services:"
kubectl get services
echo "--------------------"
echo "🔷 Deployments:"
kubectl get deployments

echo "✅ Blog platform deployment completed successfully!"
echo "💡 Tips:"
echo "  - Monitor pods:        kubectl get pods -w"
echo "  - Check pod logs:      kubectl logs <pod-name>"
echo "  - Check pod details:   kubectl describe pod <pod-name>"
echo "  - Access frontend:     minikube service frontend-service --url"
