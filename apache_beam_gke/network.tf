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
  project                 = module.default.project_id
  name                    = format("%s-%s-%s", var.prefix, var.network_name, random_id.random.hex)
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  project                  = module.default.project_id
  ip_cidr_range            = var.cidr_block
  name                     = format("%s-%s-%s", var.prefix, var.subnet_name, random_id.random.hex)
  network                  = google_compute_network.default.self_link
  private_ip_google_access = true
  region                   = var.region

  secondary_ip_range {
    ip_cidr_range = var.pod_range_cidr
    range_name    = var.pod_range_name
  }

  secondary_ip_range {
    ip_cidr_range = var.svc_range_cidr
    range_name    = var.svc_range_name
  }
}

// External access
resource "google_compute_router" "router" {
  project = module.default.project_id
  name    = "proxy-ext-access-router"
  network = google_compute_network.default.name
  region  = var.region

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  project                            = module.default.project_id
  name                               = "proxy-ext-access-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_route" "external_access" {
  project          = module.default.project_id
  dest_range       = "0.0.0.0/0"
  name             = "proxy-external-access"
  network          = google_compute_network.default.name
  next_hop_gateway = "default-internet-gateway"
}