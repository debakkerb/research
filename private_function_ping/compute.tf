/**
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
locals {
  shared_vpc_project_services = [
    "compute.googleapis.com"
  ]

  org_id    = var.organization_id == null ? null : var.organization_id
  folder_id = var.folder_id == null ? null : var.folder_id

  host_project_id    = "ping-host-${random_id.randomizer.hex}"
  service_project_id = "ping-host-${random_id.randomizer.hex}"

  private_connector_cidr = "10.100.0.0/28"
}

resource "random_id" "randomizer" {
  byte_length = 2
}

resource "google_project" "host_project" {
  name       = local.host_project_id
  project_id = local.host_project_id

  org_id          = local.org_id
  folder_id       = local.folder_id
  billing_account = var.billing_account

  depends_on = [google_organization_iam_member.xpn_admin]
}

resource "google_project_service" "host_project_services" {
  for_each = toset(local.shared_vpc_project_services)

  project = google_project.host_project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = true
}

resource "google_project" "service_project" {
  name       = local.service_project_id
  project_id = local.service_project_id

  org_id          = local.org_id
  folder_id       = local.folder_id
  billing_account = var.billing_account
}

resource "google_project_service" "service_project_services" {
  for_each = toset(local.shared_vpc_project_services)

  project = google_project.service_project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = true
}

resource "google_compute_network" "shared_vpc" {
  project                 = google_project.host_project.project_id
  name                    = "host-network"
  auto_create_subnetworks = false

  depends_on = [google_project_service.host_project_services]
}

resource "google_compute_subnetwork" "vm_subnet" {
  project = google_project.host_project.project_id

  ip_cidr_range = "10.0.0.0/16"
  name          = "host-subnetwork"
  network       = google_compute_network.shared_vpc.self_link
  region        = "europe-west1"
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = google_project.host_project.project_id
}

resource "google_compute_shared_vpc_service_project" "service" {
  host_project    = google_project.host_project.project_id
  service_project = google_project.service_project.project_id
}

data "google_compute_image" "debian" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_service_account" "compute_service_account" {
  project      = google_project.service_project.project_id
  account_id   = "compute-sa"
  display_name = "VM Service Account"
}

data "template_file" "startup_script" {
  template = ("./startup_script.sh")
}

resource "google_compute_instance" "web_server" {
  project = google_project.service_project.project_id

  name                      = "http-endpoint"
  machine_type              = "n1-standard-1"
  zone                      = "europe-west1-b"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network = google_compute_network.shared_vpc.self_link
  }

  metadata_startup_script = data.template_file.startup_script.rendered

  service_account {
    email  = google_service_account.compute_service_account.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.host_project_services
  ]
}

resource "google_compute_firewall" "vm_private_access" {
  project = google_project.host_project.project_id

  name          = "allow-http-access"
  network       = google_compute_network.shared_vpc.self_link
  source_ranges = [local.private_connector_cidr]

  target_service_accounts = [google_service_account.compute_service_account.email]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_network_peering" "shared_vpc_to_function" {
  name         = "peer-shar-fnc"
  network      = google_compute_network.shared_vpc.self_link
  peer_network = google_compute_network.private_function_network.self_link
}

resource "google_compute_network_peering" "function_to_shared_vpc" {
  name         = "peer-fnc-shar"
  network      = google_compute_network.private_function_network.self_link
  peer_network = google_compute_network.shared_vpc.self_link
}