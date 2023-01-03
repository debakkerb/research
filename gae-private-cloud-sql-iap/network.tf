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
  project                         = module.host_project.project_id
  name                            = "${var.prefix}-network"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  description                     = "Network to host a Cloud SQL instance and the private service connector for Google AppEngine."
}

resource "google_compute_subnetwork" "host_subnet" {
  project                  = module.host_project.project_id
  ip_cidr_range            = var.subnet_cidr_block
  name                     = "${var.prefix}-subnet"
  network                  = google_compute_network.host_network.self_link
  region                   = var.region
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "serverless_connector_subnet" {
  project                  = module.host_project.project_id
  ip_cidr_range            = var.serverless_connector_subnet_cidr_block
  name                     = "${var.prefix}-serverless-subnet"
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
  provider = google-beta
  project  = module.host_project.project_id

  depends_on = [
    google_compute_network.host_network,
    google_compute_subnetwork.host_subnet
  ]
}

resource "google_compute_shared_vpc_service_project" "service_project" {
  provider        = google-beta
  host_project    = module.host_project.project_id
  service_project = module.service_project.project_id

  depends_on = [
    google_compute_network.host_network,
    google_compute_subnetwork.host_subnet,
    google_compute_shared_vpc_host_project.host_project
  ]
}

resource "google_compute_firewall" "serverless_to_vpc_connector" {
  project       = module.host_project.project_id
  name          = "srvrlss-to-conn"
  network       = google_compute_network.host_network.self_link
  direction     = "INGRESS"
  source_ranges = ["107.178.230.64/26", "35.199.224.0/19"]
  target_tags   = ["vpc-connector"]

  allow {
    protocol = "tcp"
    ports    = ["667"]
  }

  allow {
    protocol = "udp"
    ports    = ["665-666"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "vpc_connector_to_serverless" {
  project            = module.host_project.project_id
  name               = "conn-to-srvrlss"
  network            = google_compute_network.host_network.self_link
  direction          = "EGRESS"
  destination_ranges = ["107.178.230.64/26", "35.199.224.0/19"]
  target_tags        = ["vpc-connector"]

  allow {
    protocol = "tcp"
    ports    = ["667"]
  }

  allow {
    protocol = "udp"
    ports    = ["665-666"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "vpc_connector_healtchecks" {
  project            = module.host_project.project_id
  name               = "vpc-connector-hc"
  network            = google_compute_network.host_network.self_link
  direction          = "EGRESS"
  destination_ranges = ["130.211.0.0/22", "35.191.0.0/16", "108.170.220.0/23"]
  target_tags        = ["vpc-connector"]

  allow {
    protocol = "tcp"
    ports    = ["667"]
  }
}

resource "google_compute_firewall" "vpc_connector_network_ingress" {
  project     = module.host_project.project_id
  name        = "vpc-conn-egress"
  network     = google_compute_network.host_network.self_link
  direction   = "INGRESS"
  source_tags = ["vpc-connector"]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_vpc_access_connector" "serverless_access_connector" {
  provider     = google-beta
  project      = module.service_project.project_id
  name         = "${var.prefix}-serverless-access-${random_id.name_randomizer.hex}"
  region       = var.region
  machine_type = var.serverless_access_machine_type

  subnet {
    name       = google_compute_subnetwork.serverless_connector_subnet.name
    project_id = module.host_project.project_id
  }
}