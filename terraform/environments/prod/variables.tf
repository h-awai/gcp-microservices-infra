variable "project_id" {
  type        = string
  default     = "<YOUR_GCP_PROJECT_ID>"
  description = "The Google Cloud Project ID."
}

variable "region" {
  type        = string
  default     = "asia-northeast1"
  description = "The Google Cloud region to deploy resources (e.g., asia-northeast1)."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment name (e.g., prod, dev)."
}

variable "alert_email" {
  type        = string
  default     = "alert-notification@example.com"
  description = "Email address for Cloud Monitoring alert notifications."
}

variable "container_image" {
  type        = string
  default     = "bsord/tetris:latest"
  description = "Container image to run on Cloud Run."
}
