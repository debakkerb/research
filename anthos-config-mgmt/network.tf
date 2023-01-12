/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
:clo
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_compute_network" "default" {
  project                 = module.project.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "default" {
  project                  = module.project.project_id
  name                     = var.subnetwork_name
  network                  = google_compute_network.default.name
  ip_cidr_range            = var.subnet_cidr_range
  private_ip_google_access = true
  region                   = var.region
}

resource "google_compute_router" "egress_router" {
  project = module.project.project_id
  name    = "internet-egress-router"
  network = google_compute_network.default.self_link
  region  = var.region

  bgp {
    asn = 65515
  }
}

resource "google_compute_router_nat" "default" {
  project                            = module.project.project_id
  name                               = "internet-egress-nat"
  router                             = google_compute_router.egress_router.name
  region                             = var.region
  nat_ip_allocate_option           = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_route" "egress_access" {
  project          = module.project.project_id
  dest_range       = "0.0.0.0/0"
  name             = "proxy-external-access"
  network          = google_compute_network.default.name
  next_hop_gateway = "default-internet-gateway"
}
