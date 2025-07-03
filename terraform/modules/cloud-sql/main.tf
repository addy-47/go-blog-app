resource "google_sql_database_instance" "main" {
  database_version = "MYSQL_8_0" # Or MYSQL_8_0, etc.
  name             = "${var.database_name}-instance"
  project          = var.gcp_project_id
  region           = var.gcp_region
  deletion_protection = false
  settings {
    tier = "db-f1-micro" # Smallest tier for testing
    ip_configuration {
      ipv4_enabled = true
      # You might want to restrict authorized_networks in a production environment
      # authorized_networks { value = "0.0.0.0/0" }
    }
  }
}

resource "google_sql_database" "main" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  project  = var.gcp_project_id
}

variable "gcp_project_id" { type = string }
variable "gcp_region" { type = string }
variable "database_name" {
  description = "The name of the database to create."
  type        = string
}

output "instance_connection_name" { value = google_sql_database_instance.main.connection_name }
output "database_name" { value = google_sql_database.main.name }