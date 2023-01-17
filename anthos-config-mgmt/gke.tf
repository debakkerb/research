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

resource "google_service_account" "cluster_identity" {
  project     = module.project.project_id
  account_id  = var.acm_cluster_identity_name
  description = "Identity attached to the GKE cluster hosting the ACM components"
}

resource "google_project_iam_member" "cluster_identity_permissions" {
  for_each = toset(["roles/container.nodeServiceAccount"])
  project  = module.project.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.cluster_identity.email}"
}

resource "google_container_cluster" "acm_cluster" {
  project          = module.project.project_id
  name             = var.acm_cluster_name
  location         = var.acm_cluster_location
  network          = google_compute_network.default.name
  subnetwork       = google_compute_subnetwork.default.name
  enable_autopilot = true

  release_channel {
    channel = "STABLE"
  }

  private_cluster_config {
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.acm_cluster_master_cidr_block

    master_global_access_config {
      enabled = true
    }
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block = ""
    services_ipv4_cidr_block = ""
  }

  depends_on = [
    google_project_iam_member.cluster_identity_permissions
  ]
}

