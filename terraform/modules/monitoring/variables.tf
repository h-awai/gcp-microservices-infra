variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID."
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service to monitor."
}

variable "alert_email" {
  type        = string
  default     = "alert-notification@example.com"
  description = "Email address for Cloud Monitoring alert notifications."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment name (e.g., prod, dev)."
}
