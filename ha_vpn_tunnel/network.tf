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
# VPC 1
resource "google_compute_network" "public_vpc_1" {
  name                    = "public-vpc-1"
  project                 = module.project_vpc_1.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public_subnet_1" {
  ip_cidr_range = "10.0.0.0/24"
  name          = "sn-eu-west-1"
  network       = google_compute_network.public_vpc_1.self_link
  region        = "europe-west1"
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_1.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "public_subnet_2" {
  ip_cidr_range = "10.0.1.0/24"
  name          = "sn-eu-west-2"
  network       = google_compute_network.public_vpc_1.self_link
  region        = "europe-west2"
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_1.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

#VPC 2
resource "google_compute_network" "private_vpc_2" {
  name                    = "private-vpc-2"
  project                 = module.project_vpc_2.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet_1" {
  ip_cidr_range = "10.0.2.0/24"
  name          = "sn-eu-west-1"
  region        = "europe-west1"
  network       = google_compute_network.private_vpc_2.self_link
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_2.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnet_2" {
  ip_cidr_range = "10.0.3.0/24"
  name          = "sn-eu-west-3"
  region        = "europe-west3"
  network       = google_compute_network.private_vpc_2.self_link
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_2.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}