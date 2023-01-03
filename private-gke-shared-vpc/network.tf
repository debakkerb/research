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

# Host Network
resource "google_compute_network" "gke_host_network" {
  project                 = module.gke_host_project.project_id
  name                    = "${var.network_name}-${random_id.randomizer.hex}"
  auto_create_subnetworks = false
  description             = "Host Network for GKE clusters"
}

# Subnetworks
resource "google_compute_subnetwork" "gke_host_subnet_1" {
  project                  = module.gke_host_project.project_id
  ip_cidr_range            = "10.0.4.0/22"
  name                     = "${var.network_name}-sn-euw1"
  network                  = google_compute_network.gke_host_network.self_link
  region                   = "europe-west1"
  private_ip_google_access = true

  secondary_ip_range {
    ip_cidr_range = "10.4.0.0/14"
    range_name    = "gke-pod-euw1-secondary"
  }

  secondary_ip_range {
    ip_cidr_range = "10.0.32.0/20"
    range_name    = "gke-svc-euw1-secondary"
  }
}

resource "google_compute_subnetwork" "gke_host_subnet_2" {
  project                  = module.gke_host_project.project_id
  name                     = "${var.network_name}-sn-euw2"
  network                  = google_compute_network.gke_host_network.self_link
  ip_cidr_range            = "172.16.4.0/22"
  region                   = "europe-west2"
  private_ip_google_access = true

  secondary_ip_range {
    ip_cidr_range = "172.20.0.0/14"
    range_name    = "gke-pod-euw2-secondary"
  }

  secondary_ip_range {
    ip_cidr_range = "172.16.16.0/20"
    range_name    = "gke-service-euw2-secondary"
  }
}

# Shared VPC
resource "google_compute_shared_vpc_host_project" "host_project_config" {
  project = module.gke_host_project.project_id
}

resource "google_compute_shared_vpc_service_project" "svc_one_attachment" {
  host_project    = module.gke_host_project.project_id
  service_project = module.gke_svc_one.project_id

  depends_on = [
    google_compute_shared_vpc_host_project.host_project_config
  ]
}

resource "google_compute_shared_vpc_service_project" "svc_two_attachment" {
  host_project    = module.gke_host_project.project_id
  service_project = module.gke_svc_two.project_id

  depends_on = [
    google_compute_shared_vpc_host_project.host_project_config
  ]
}