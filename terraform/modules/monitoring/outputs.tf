output "notification_channel_id" {
  value       = google_monitoring_notification_channel.email.id
  description = "The ID of the Cloud Monitoring notification channel."
}

output "alert_policy_id" {
  value       = google_monitoring_alert_policy.cpu_high.id
  description = "The ID of the Cloud Monitoring alert policy."
}
