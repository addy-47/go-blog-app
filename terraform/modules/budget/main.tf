resource "google_monitoring_notification_channel" "gchat_channel" {
  display_name = "Google Chat Budget Alerts"
  type         = "google_chat"
   labels = {
    space = var.gchat_space_id
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

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.75
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.gchat_channel.id]
    disable_default_iam_recipients = true
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

variable "gchat_space_id" {
  description = "Google Chat space ID (e.g., spaces/AAQALXamGZk)"
  type        = string
}