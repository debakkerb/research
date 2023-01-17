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

resource "google_compute_network" "default" {
  project                 = module.project.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  project                  = module.project.project_id
  name                     = var.subnet_name
  network                  = google_compute_network.default.name
  private_ip_google_access = true
  ip_cidr_range            = var.cidr_range
  region                   = var.region
}

resource "google_compute_router" "default" {
  project = module.project.project_id
  name    = "rtr-egress-traffic"
  network = google_compute_network.default.name
  region  = var.region

  bgp {
    asn = 64515
  }
}

resource "google_compute_router_nat" "default" {
  project                            = module.project.project_id
  name                               = "nat-egress"
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  router                             = google_compute_router.router.0.name

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_route" "egress_traffic_route" {
  project          = module.project.project_id
  name             = "proxy-external-access"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.default.self_link
  next_hop_gateway = "default-internet-gateway"
}

