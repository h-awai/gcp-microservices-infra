terraform {
  backend "gcs" {
    bucket = "<YOUR_UNIQUE_GCS_BUCKET_NAME>"
    prefix = "terraform/state/prod"
  }
}
