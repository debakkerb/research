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

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = "${var.prefix}-lb-mig-tst"
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "compute.googleapis.com",
  ]
}

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

