resource "kubernetes_namespace" "main" {
  metadata {
    name = var.name
  }
}

variable "name" {
  description = "The name of the Kubernetes namespace."
  type        = string
}

output "name" { value = kubernetes_namespace.main.metadata[0].name }