resource "google_cloud_run_v2_service" "web" {
  name     = "${var.environment}-web-service"
  location = var.location
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      ports {
        container_port = var.container_port
      }
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# 外部からの未認証HTTP(S)アクセスを許可
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = google_cloud_run_v2_service.web.location
  name     = google_cloud_run_v2_service.web.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
