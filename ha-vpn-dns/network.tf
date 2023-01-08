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

resource "google_compute_network" "network_one" {
  project                 = module.vpn_project.project_id
  name                    = var.network_one_name
  auto_create_subnetworks = false
}

resource "google_compute_network" "network_two" {
  project                 = module.vpn_project.project_id
  name                    = var.network_two_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork_one" {
  project                  = module.vpn_project.project_id
  name                     = var.subnet_one_name
  network                  = google_compute_network.network_one.name
  ip_cidr_range            = var.subnet_one_cidr_range
  private_ip_google_access = true
  region                   = var.subnet_one_region
}

resource "google_compute_subnetwork" "subnetwork_two" {
  project                  = module.vpn_project.project_id
  name                     = var.subnet_two_name
  network                  = google_compute_network.network_two.name
  ip_cidr_range            = var.subnet_two_cidr_range
  private_ip_google_access = true
  region                   = var.subnet_two_region
}

resource "google_compute_router" "network_one_router" {
  project     = module.vpn_project.project_id
  name        = var.network_one_router_name
  network     = google_compute_network.network_one.name
  description = "Router in network ${google_compute_network.network_one.name}, region ${var.vpn_gateway_region}"
  region      = var.vpn_gateway_region

  bgp {
    asn = 64514
  }
}

resource "google_compute_router" "network_two_router" {
  project     = module.vpn_project.project_id
  name        = var.network_two_router_name
  network     = google_compute_network.network_two.name
  description = "Router in network ${google_compute_network.network_two.name}, region ${var.vpn_gateway_region}"
  region      = var.vpn_gateway_region

  bgp {
    asn = 64515
  }
}

resource "google_compute_firewall" "iap_ssh_access_rule" {
  for_each = {
    "${google_compute_network.network_one.name}" = google_service_account.vm_one_identity.email,
    "${google_compute_network.network_two.name}" = google_service_account.vm_two_identity.email
  }

  project     = module.vpn_project.project_id
  name        = "ssh-iap-access-${each.key}"
  network     = each.key
  description = "Firewall rule to allow SSH access to both VMs."

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]

  target_service_accounts = [each.value]
}

resource "google_compute_firewall" "ping_access" {
  for_each = {
    "${google_compute_network.network_one.name}" = {
      service_account = google_service_account.vm_one_identity.email
      source_range    = var.subnet_two_cidr_range
    },
    "${google_compute_network.network_two.name}" = {
      service_account = google_service_account.vm_two_identity.email
      source_range    = var.subnet_one_cidr_range
    }
  }

  project     = module.vpn_project.project_id
  name        = "icmp-access-${each.key}"
  network     = each.key
  description = "Firewall rule to allow VMs to ping each other"

  allow {
    protocol = "icmp"
    ports    = []
  }

  target_service_accounts = [each.value.service_account]

  source_ranges = [each.value.source_range]
}

resource "google_project_iam_member" "tcp_iam_access" {
  for_each = var.trusted_users
  project  = module.vpn_project.project_id
  role     = "roles/compute.instanceAdmin.v1"
  member   = each.value
}

