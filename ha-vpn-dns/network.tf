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
  project = module.vpn_project.project_id
  name    = var.network_two_name
}

resource "google_compute_subnetwork" "subnetwork_one" {
  project                  = module.vpn_project.project_id
  name                     = var.subnet_one_name
  network                  = google_compute_network.network_one.name
  ip_cidr_range            = var.subnet_one_cidr_range
  private_ip_google_access = true
  region                   = var.subnet_one_region
}