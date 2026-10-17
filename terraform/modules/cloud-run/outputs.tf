output "service_id" {
  value       = google_cloud_run_v2_service.web.id
  description = "The ID of the Cloud Run service."
}

output "service_name" {
  value       = google_cloud_run_v2_service.web.name
  description = "The name of the Cloud Run service."
}

output "uri" {
  value       = google_cloud_run_v2_service.web.uri
  description = "The main URI in which this Service is serving traffic."
}

output "location" {
  value       = google_cloud_run_v2_service.web.location
  description = "The location of the Cloud Run service."
}
