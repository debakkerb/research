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

module "host_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 10.3"

  name              = "${var.prefix}-host-${var.suffix}"
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.parent_folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "compute.googleapis.com",
  ]
}

module "service_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 10.3"

  name              = "${var.prefix}-svc-${var.suffix}"
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.parent_folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "compute.googleapis.com",
  ]
}

resource "google_compute_network" "default" {
  project                         = module.host_project.project_id
  name                            = "${var.prefix}-nw-${var.suffix}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  description                     = "Host network"
}

resource "google_compute_subnetwork" "region_one" {
  project                  = module.host_project.project_id
  ip_cidr_range            = var.subnet_cidr_block_region_one
  name                     = "${var.prefix}-snw-${var.suffix}-one"
  network                  = google_compute_network.default.self_link
  region                   = var.region_one
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "region_two" {
  project                  = module.host_project.project_id
  ip_cidr_range            = var.subnet_cidr_block_region_two
  name                     = "${var.prefix}-snw-${var.suffix}-one"
  network                  = google_compute_network.default.self_link
  region                   = var.region_two
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_shared_vpc_host_project" "default" {
  project = module.host_project.project_id

  depends_on = [
    google_compute_network.default,
    google_compute_subnetwork.region_one,
    google_compute_subnetwork.region_two
  ]
}

resource "google_compute_shared_vpc_service_project" "default" {
  host_project    = module.host_project.project_id
  service_project = module.service_project.project_id

  depends_on = [
    google_compute_network.default,
    google_compute_subnetwork.region_one,
    google_compute_subnetwork.region_two,
    google_compute_shared_vpc_host_project.default
  ]
}