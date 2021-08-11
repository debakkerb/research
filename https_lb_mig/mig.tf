/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_service_account" "instance_identity" {
  project      = module.project.project_id
  account_id   = "${var.prefix}-mig-identity"
  display_name = "MIG Instance Identity"
  description  = "Service account attached to instances in the managed instance group."
}

resource "google_project_iam_member" "log_access" {
  project = module.project.project_id
  member  = "serviceAccount:${google_service_account.instance_identity.email}"
  role    = "roles/logging.logWriter"
}

data "google_compute_image" "debian" {
  project = "debian-cloud"
  family  = "debian-10"
}

data "google_compute_zones" "zones" {
  project = module.project.project_id
  region  = var.region
}

resource "google_compute_instance_template" "default" {
  project                 = module.project.project_id
  name                    = "${var.prefix}-instance"
  description             = "Instance template for the Apache hosts."
  region                  = var.region
  machine_type            = "n2-standard-2"
  metadata_startup_script = file("${path.module}/scripts/startup.sh")

  disk {
    boot         = true
    auto_delete  = true
    disk_size_gb = 20
    source_image = data.google_compute_image.debian.self_link
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.self_link
  }

  service_account {
    email  = google_service_account.instance_identity.email
    scopes = ["cloud-platform"]
  }

  tags = ["web-app-backend"]
}

resource "google_compute_instance_template" "canary" {
  project                 = module.project.project_id
  name                    = "${var.prefix}-canary-instance"
  description             = "Instance template for the Apache hosts."
  region                  = var.region
  machine_type            = "n2-standard-2"
  metadata_startup_script = file("${path.module}/scripts/startup.sh")

  disk {
    boot         = true
    auto_delete  = true
    disk_size_gb = 20
    source_image = data.google_compute_image.debian.self_link
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.self_link
  }

  service_account {
    email  = google_service_account.instance_identity.email
    scopes = ["cloud-platform"]
  }

  tags = ["web-app-backend"]
}

resource "google_compute_region_instance_group_manager" "default" {
  project            = module.project.project_id
  name               = "${var.prefix}-mig-manager"
  base_instance_name = "${var.prefix}-web"
  description        = "Instance Group manager for Apache weblayer."
  region             = var.region
  target_size        = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.backend_health_check.id
    initial_delay_sec = 300
  }

  named_port {
    name = "http"
    port = 80
  }

  version {
    name              = "backend-main"
    instance_template = google_compute_instance_template.default.id
  }

  version {
    name              = "backend-canary"
    instance_template = google_compute_instance_template.canary.id
    target_size {
      fixed = 1
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_autoscaler" "default" {
  project = module.project.project_id
  name    = "${var.prefix}-apache-mig-scaler"
  target  = google_compute_region_instance_group_manager.default.id
  region  = var.region

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 90

    cpu_utilization {
      target = 0.75
    }
  }
}
