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

resource "google_compute_network" "host_network" {
  project                         = module.cloud_sql_proxy_host_project.project_id
  name                            = "${var.prefix}-sql-nw"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  description                     = "Host network for the Cloud SQL instance and proxy"
}

resource "google_compute_subnetwork" "sql_subnetwork" {
  project                  = module.cloud_sql_proxy_host_project.project_id
  ip_cidr_range            = var.subnet_cidr_range
  name                     = "${var.prefix}-sql-snw"
  network                  = google_compute_network.host_network.self_link
  region                   = var.region
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_shared_vpc_host_project" "host_project" {
  project = module.cloud_sql_proxy_host_project.project_id

  depends_on = [
    google_compute_network.host_network,
    google_compute_subnetwork.sql_subnetwork
  ]
}

resource "google_compute_shared_vpc_service_project" "service_project" {
  host_project    = module.cloud_sql_proxy_host_project.project_id
  service_project = module.cloud_sql_proxy_service_project.project_id

  depends_on = [
    google_compute_network.host_network,
    google_compute_subnetwork.sql_subnetwork,
    google_compute_shared_vpc_host_project.host_project
  ]
}

// Firewall rule

resource "google_compute_firewall" "iap_ingress_firewall" {
  project   = module.cloud_sql_proxy_host_project.project_id
  name      = "allow-iap-ingress"
  network   = google_compute_network.host_network.self_link
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["5432"]

  }

  source_ranges = [
    "35.235.240.0/20"
  ]

  target_service_accounts = [
    google_service_account.sql_proxy_service_account.email
  ]
}

resource "google_compute_firewall" "ssh_ingress_firewall" {
  count     = var.block_ssh ? 0 : 1
  project   = module.cloud_sql_proxy_host_project.project_id
  name      = "allow-ssh-ingress"
  network   = google_compute_network.host_network.self_link
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    "35.235.240.0/20"
  ]

  target_service_accounts = [
    google_service_account.sql_proxy_service_account.email
  ]
}

// External access
resource "google_compute_router" "router" {
  count = var.block_egress ? 0 : 1

  project = module.cloud_sql_proxy_host_project.project_id
  name    = "proxy-ext-access-router"
  network = google_compute_network.host_network.self_link
  region  = var.region

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  count = var.block_egress ? 0 : 1

  project                            = module.cloud_sql_proxy_host_project.project_id
  name                               = "proxy-ext-access-nat"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_route" "external_access" {
  count = var.block_egress ? 0 : 1

  project          = module.cloud_sql_proxy_host_project.project_id
  dest_range       = "0.0.0.0/0"
  name             = "proxy-external-access"
  network          = google_compute_network.host_network.name
  next_hop_gateway = "global/gateways/default-internet-gateway"
}

