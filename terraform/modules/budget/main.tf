resource "google_monitoring_notification_channel" "gchat_channel" {
  project      = var.project_id
  display_name = "Google Chat Budget Alerts"
  type         = "webhook_gchat"
  labels = {
    url = var.gchat_webhook_url
  }
}

resource "google_billing_budget" "project_budget" {
  billing_account = var.billing_account_id
  display_name    = "Project Budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = floor(var.budget_amount)
      nanos         = (var.budget_amount - floor(var.budget_amount)) * 1000000000
    }
  }

  dynamic "threshold_rules" {
    for_each = toset(var.budget_thresholds)
    content {
      threshold_percent = threshold_rules.value
    }
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.gchat_channel.id]
    disable_default_iam_recipients   = true
  }
}

variable "project_id" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "budget_amount" {
  type = number
}

variable "gchat_webhook_url" {
  type = string
}

variable "budget_thresholds" {
  description = "A list of budget threshold percentages to alert on (e.g., [0.5, 0.9, 1.0])."
  type        = list(number)
  default     = [0.5, 0.75, 1.0]
}