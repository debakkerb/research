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

data "google_compute_image" "debian" {
  project = "debian-cloud"
  family  = "debian-10"
}

resource "google_service_account" "instance_identity" {
  project    = var.project_id
  account_id = "${var.prefix}-vm-id-${var.suffix}"
}

resource "google_compute_instance" "default" {
  project                   = var.project_id
  machine_type              = "n1-standard-1"
  name                      = "${var.prefix}-inst-${var.suffix}"
  zone                      = var.zone
  allow_stopping_for_update = true
  deletion_protection       = false

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
    }
  }

  network_interface {
    subnetwork = var.subnet_selflink
  }

  service_account {
    email  = google_service_account.instance_identity.email
    scopes = ["cloud-platform"]
  }

}

resource "google_compute_project_metadata_item" "oslogin" {
  project = var.project_id
  key     = "oslogin-enabled"
  value   = "TRUE"
}