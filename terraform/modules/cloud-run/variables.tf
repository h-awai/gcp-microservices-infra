variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID."
}

variable "location" {
  type        = string
  default     = "asia-northeast1"
  description = "The Google Cloud region to deploy resources (e.g., asia-northeast1)."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment name (e.g., prod, dev)."
}

variable "container_image" {
  type        = string
  default     = "bsord/tetris:latest"
  description = "Container image to run on Cloud Run."
}

variable "container_port" {
  type        = number
  default     = 80
  description = "Port exposed by the container."
}
