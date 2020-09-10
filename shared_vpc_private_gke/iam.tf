# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "google_compute_subnetwork_iam_member" "service_1_robot_network_user" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.service_1_robot_sa}"
  region     = "europe-west1"
  subnetwork = google_compute_subnetwork.gke_host_subnet_1.self_link
  role       = "roles/compute.networkUser"
}

resource "google_compute_subnetwork_iam_member" "service_2_robot_network_user" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.service_2_robot_sa}"
  subnetwork = google_compute_subnetwork.gke_host_subnet_2.self_link
  region     = "europe-west2"
  role       = "roles/compute.networkUser"
}

resource "google_compute_subnetwork_iam_member" "google_api_svc1_host" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.google_api_svc1_sa}"
  subnetwork = google_compute_subnetwork.gke_host_subnet_1.self_link
  region     = "europe-west1"
  role       = "roles/compute.networkUser"
}

resource "google_compute_subnetwork_iam_member" "google_api_svc2_host" {
  project    = module.gke_host_project.project_id
  member     = "serviceAccount:${local.google_api_svc2_sa}"
  subnetwork = google_compute_subnetwork.gke_host_subnet_2.self_link
  region     = "europe-west2"
  role       = "roles/compute.networkUser"
}

// Host Service Agent User
resource "google_project_iam_member" "host_agent_svc_1" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${local.service_1_robot_sa}"
  role    = "roles/container.hostServiceAgentUser"
}

resource "google_project_iam_member" "host_agent_svc_2" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${local.service_2_robot_sa}"
  role    = "roles/container.hostServiceAgentUser"
}

// Custom service account for the GKE clusters.
resource "google_service_account" "gke_svc1_service_account" {
  project      = module.gke_svc_one.project_id
  account_id   = "gke-operator"
  display_name = "GKE Operator"
  description  = "GKE Operator for the GKE cluster."
}

resource "google_service_account" "gke_svc2_service_account" {
  project      = module.gke_svc_two.project_id
  account_id   = "gke-operator"
  display_name = "GKE Operator"
  description  = "GKE Operator for the GKE cluster."
}

resource "google_project_iam_member" "gke_svc1_sa_iam_permissions" {
  for_each = toset(local.gke_operator_sa_roles)
  project  = module.gke_svc_one.project_id
  member   = "serviceAccount:${google_service_account.gke_svc1_service_account.email}"
  role     = each.value
}

resource "google_project_iam_member" "gke_svc1_fwl_permissions" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${google_service_account.gke_svc1_service_account.email}"
  role    = "roles/compute.securityAdmin"
}

resource "google_project_iam_member" "gke_svc2_sa_iam_permissions" {
  for_each = toset(local.gke_operator_sa_roles)
  project  = module.gke_svc_two.project_id
  member   = "serviceAccount:${google_service_account.gke_svc2_service_account.email}"
  role     = each.value
}

resource "google_project_iam_member" "gke_svc2_fwl_permissions" {
  project = module.gke_host_project.project_id
  member  = "serviceAccount:${google_service_account.gke_svc2_service_account.email}"
  role    = "roles/compute.securityAdmin"
}