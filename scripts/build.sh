#!/bin/bash
set -e  # Exit on any error

# Build all Docker images using Minikube's Docker daemon
echo "🚀 Starting build process..."

echo "🔄 Configuring Minikube's Docker environment..."
eval $(minikube docker-env) || {
    echo "❌ Error: Failed to configure Minikube's Docker environment"
    exit 1
}

# Check if minikube is running
if ! minikube status >/dev/null 2>&1; then
    echo "❌ Error: Minikube is not running"
    exit 1
fi

# Set up Minikube's Docker environment
eval $(minikube docker-env) || {
    echo "❌ Error: Failed to configure Minikube's Docker environment"
    exit 1
}

# Store the root directory
ROOT_DIR=$(pwd)

for service in backend frontend worker logging-agent; do
    echo "🔨 Building $service..."
    
    # Check if service directory exists
    if [ ! -d "$service" ]; then
        echo "❌ Error: $service directory not found"
        continue
    fi
    
    cd "$service" || {
        echo "❌ Error: Failed to enter $service directory"
        exit 1
    }
    
    # Build Go binary
    echo "📦 Compiling Go binary for $service..."
    go build -o $service || {
        echo "❌ Error: Go build failed for $service"
        cd "$ROOT_DIR"
        exit 1
    }
    
    # Build Docker image
    echo "🐳 Building Docker image for $service..."
    docker build -t $service:latest . || {
        echo "❌ Error: Docker build failed for $service"
        cd "$ROOT_DIR"
        exit 1
    }
    
    cd "$ROOT_DIR"
    echo "✅ Successfully built $service"
    echo "-------------------"
done

echo "🎉 All images built successfully!"