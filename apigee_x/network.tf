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

resource "google_compute_network" "default" {
  project                         = module.default.project_id
  name                            = "${var.prefix}-nw"
  auto_create_subnetworks         = false
  description                     = "Network to be peered with Apigee X resources."
}

resource "google_compute_subnetwork" "default" {
  project                  = module.default.project_id
  ip_cidr_range            = var.cidr_block
  name                     = "${var.prefix}-snw"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_global_address" "default" {
  project       = module.default.project_id
  name          = "${var.prefix}-svc-conn-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 22
  network       = google_compute_network.default.id
  description   = "Peering range for Google Apigee services."
}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.default.self_link
  reserved_peering_ranges = [google_compute_global_address.default.name]
  service                 = "servicenetworking.googleapis.com"
}

