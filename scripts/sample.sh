#!bin/bash

echo "this is what i created initally but it crashed silently and then the 
terminal crashed as well still dont know why"

helm uninstall blog-platform
helm install blog-platform 
kubectl apply -f crds/blogpost-crd.yaml
kubectl apply -f k9s-security/istio.yaml

echo "Helm chart installed ,CRD and istio applied successfully."