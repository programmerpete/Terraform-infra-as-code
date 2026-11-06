locals {
  required_services = toset([
    "run.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each           = local.required_services
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "runtime" {
  account_id   = "secure-api-runtime"
  display_name = "Secure API runtime"
  depends_on   = [google_project_service.required]
}

resource "google_cloud_run_v2_service" "api" {
  name                = "secure-api"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.runtime.email
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      ports {
        container_port = 8080
      }
    }
    scaling {
      max_instance_count = 2
    }
  }
  depends_on = [google_project_service.required]
}

# Deliberately no allUsers Cloud Run invoker IAM binding.
