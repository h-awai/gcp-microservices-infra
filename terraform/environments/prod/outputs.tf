output "cloud_run_url" {
  value       = module.cloud_run.uri
  description = "The public HTTPS URL to access the deployed Web application on Cloud Run."
}

output "cloud_run_service_name" {
  value       = module.cloud_run.service_name
  description = "The name of the Cloud Run service."
}

output "monitoring_alert_policy_id" {
  value       = module.monitoring.alert_policy_id
  description = "The ID of the Cloud Monitoring Alert Policy."
}

output "monitoring_notification_channel_id" {
  value       = module.monitoring.notification_channel_id
  description = "The ID of the Cloud Monitoring Notification Channel."
}
