/**
 * Copyright 2023 Google LLC
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
  family  = var.vm_image_family
  project = var.vm_image_project
}

resource "google_service_account" "vm_one_identity" {
  project      = module.vpn_project.project_id
  account_id   = var.vm_one_identity_name
  display_name = var.vm_one_identity_name
  description  = "Service account, attached to the VM created in the first network."
}

resource "google_service_account" "vm_two_identity" {
  project      = module.vpn_project.project_id
  account_id   = var.vm_two_identity_name
  display_name = var.vm_two_identity_name
  description  = "Service account, attached to the VM created in the second network."
}

resource "google_compute_instance" "vm_one" {
  project                   = module.vpn_project.project_id
  name                      = var.vm_one_name
  machine_type              = var.vm_one_machine_type
  zone                      = var.vm_one_zone
  tags                      = var.vm_one_tags
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork_one.self_link
  }

  service_account {
    email  = google_service_account.vm_one_identity.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "vm_two" {
  project                   = module.vpn_project.project_id
  name                      = var.vm_two_name
  machine_type              = var.vm_two_machine_type
  zone                      = var.vm_two_zone
  tags                      = var.vm_two_tags
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork_two.self_link
  }

  service_account {
    email  = google_service_account.vm_two_identity.email
    scopes = ["cloud-platform"]
  }
}

resource "google_service_account_iam_member" "vm_one_access" {
  for_each           = var.trusted_users
  service_account_id = google_service_account.vm_one_identity.id
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

resource "google_service_account_iam_member" "vm_two_access" {
  for_each           = var.trusted_users
  service_account_id = google_service_account.vm_two_identity.id
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

resource "google_compute_instance_iam_member" "vm_one_tcp_access" {
  for_each      = var.trusted_users
  zone          = google_compute_instance.vm_one.zone
  instance_name = google_compute_instance.vm_one.name
  role          = "roles/iap.tunnelResourceAccessor"
  member        = each.value
}

resource "google_compute_instance_iam_member" "vm_two_tcp_access" {
  for_each      = var.trusted_users
  project       = module.vpn_project.project_id
  zone          = google_compute_instance.vm_two.zone
  instance_name = google_compute_instance.vm_two.name
  role          = "roles/iap.tunnelResourceAccessor"
  member        = each.value
}

