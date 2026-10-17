module "cloud_run" {
  source          = "../../modules/cloud-run"
  project_id      = var.project_id
  location        = var.region
  environment     = var.environment
  container_image = var.container_image
  container_port  = 80
}

module "monitoring" {
  source       = "../../modules/monitoring"
  project_id   = var.project_id
  service_name = module.cloud_run.service_name
  alert_email  = var.alert_email
  environment  = var.environment
}
