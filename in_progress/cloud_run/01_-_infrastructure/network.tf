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
  project                 = module.gke_run_demo_project.project_id
  name                    = "gke-run-demo-nw"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  project                  = module.gke_run_demo_project.project_id
  ip_cidr_range            = "10.0.0.0/16"
  name                     = "gke-run-demo-snw"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-svc-range"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-pod-range"
    ip_cidr_range = "10.2.0.0/16"
  }
}