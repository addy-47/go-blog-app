#!/bin/bash

echo "🧹 Starting cleanup process..."

# Function to safely run commands
safe_run() {
    echo "Running: $*"
    if ! "$@"; then
        echo "⚠️ Warning: Command failed: $*"
        return 1
    fi
}

# Remove Helm release
echo "🗑️ Removing Helm release..."
if helm list -q | grep -q "blog-platform"; then
    safe_run helm uninstall blog-platform
fi

# Remove CRD
echo "🗑️ Removing BlogPost CRD..."
if kubectl get crd blogposts.demo.example.com &>/dev/null; then
    safe_run kubectl delete crd blogposts.demo.example.com
else
    echo "ℹ️ BlogPost CRD not found, skipping..."
fi

# Remove Istio configurations
echo "🗑️ Removing Istio configurations..."
if [ -f "k8s-security/istio.yaml" ]; then
    safe_run kubectl delete -f k8s-security/istio.yaml
fi

# Remove PVCs (without --force first)
echo "🗑️ Removing Persistent Volume Claims..."
if kubectl get pvc --no-headers 2>/dev/null | grep -q .; then
    kubectl delete pvc --all --timeout=30s || {
        echo "⚠️ Normal deletion failed, trying force deletion..."
        kubectl delete pvc --all --grace-period=0 --force
    }
fi

# Remove resources with proper timeout
echo "🧹 Cleaning up remaining resources..."
kubectl delete pods,services,deployments,statefulsets,configmaps,secrets -l app=blog-platform --timeout=30s || {
    echo "⚠️ Normal deletion failed, trying force deletion..."
    kubectl delete pods,services,deployments,statefulsets,configmaps,secrets -l app=blog-platform --grace-period=0 --force
}

# Final verification
echo "🔍 Verifying cleanup..."
kubectl get all -l app=blog-platform

echo "✨ Cleanup completed!"