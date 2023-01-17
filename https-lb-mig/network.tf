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
  project                         = module.project.project_id
  name                            = "${var.prefix}-lb-mig-nw"
  description                     = "Network to host a managed instance group + external load balancer."
  delete_default_routes_on_create = true
  auto_create_subnetworks         = false
}

resource "google_compute_subnetwork" "default" {
  project       = module.project.project_id
  ip_cidr_range = var.cidr_range
  name          = "${var.prefix}-lb-mig-snw"
  network       = google_compute_network.default.self_link
  region        = var.region
}

resource "google_compute_router" "router" {
  count   = var.enable_egress_traffic ? 1 : 0
  project = module.project.project_id
  name    = "${var.prefix}-rtr-egress-traffic"
  network = google_compute_network.default.self_link
  region  = var.region

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  count                              = var.enable_egress_traffic ? 1 : 0
  project                            = module.project.project_id
  name                               = "${var.prefix}-nat-rtr-egress"
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
  count            = var.enable_egress_traffic ? 1 : 0
  project          = module.project.project_id
  name             = "${var.prefix}-proxy-external-access"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.default.self_link
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_firewall" "iap_access" {
  count     = var.enable_iap_access ? 1 : 0
  name      = "${var.prefix}-enable-iap-access"
  project   = module.project.project_id
  network   = google_compute_network.default.self_link
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    "35.235.240.0/20"
  ]

  target_tags = ["iap"]
}
