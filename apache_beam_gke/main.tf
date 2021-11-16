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

locals {
  project_name = format("%s-%s-%s", var.prefix, var.project_name, random_id.random.hex)

  gke_operator_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
}

resource "random_id" "random" {
  byte_length = 2
}

module "default" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = local.project_name
  random_project_id = false
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "container.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com"
  ]
}
resource "google_service_account" "cluster_identity" {
  project    = module.default.project_id
  account_id = "cluster-id"
}

resource "google_project_iam_member" "cluster_identity_permissions" {
  for_each = toset(local.gke_operator_sa_roles)
  project  = module.default.project_id
  member   = "serviceAccount:${google_service_account.cluster_identity.email}"
  role     = each.value
}

resource "google_service_account" "workload_identity" {
  project    = module.default.project_id
  account_id = "workload-id"
}

resource "google_container_cluster" "default" {
  project                  = module.default.project_id
  name                     = var.cluster_name
  remove_default_node_pool = true
  initial_node_count       = 1
  location                 = var.zone
  network                  = google_compute_network.default.self_link
  subnetwork               = google_compute_subnetwork.default.self_link
  min_master_version       = var.cluster_version

  release_channel {
    channel = var.channel
  }

  ip_allocation_policy {
    services_secondary_range_name = var.svc_range_name
    cluster_secondary_range_name  = var.pod_range_name
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  node_config {
    service_account = google_service_account.cluster_identity.email
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring"
    ]
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  depends_on = [
    google_project_iam_member.cluster_identity_permissions
  ]
}

resource "google_container_node_pool" "default" {
  provider   = google-beta
  project    = module.default.project_id
  name       = "${google_container_cluster.default.name}-nodes"
  cluster    = google_container_cluster.default.name
  location   = var.zone
  node_count = 1

  node_config {
    image_type   = "cos_containerd"
    machine_type = "n2-standard-4"

    service_account = google_service_account.cluster_identity.email
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring"
    ]

    disk_size_gb = 20
    disk_type    = "pd-ssd"
  }


  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  depends_on = [
    google_project_iam_member.cluster_identity_permissions
  ]
}