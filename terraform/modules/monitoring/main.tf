# Email Notification Channel
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "${var.environment}-ops-email-channel"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# Alert Policy for Cloud Run CPU Utilization >= 80%
resource "google_monitoring_alert_policy" "cpu_high" {
  project      = var.project_id
  display_name = "${var.environment}-cloud-run-cpu-high-alert"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run CPU Utilization > 80% for 2 minutes"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.service_name}\" AND metric.type = \"run.googleapis.com/container/cpu/utilizations\""
      duration        = "120s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id
  ]

  alert_strategy {
    auto_close = "604800s"
  }

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
