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

resource "google_container_cluster" "default" {
  project    = module.project.project_id
  name       = "${var.prefix}-td-tst"
  location   = var.region
  network    = google_compute_network.network.self_link
  subnetwork = google_compute_subnetwork.subnetwork.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "RAPID"
  }

  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = local.pod_secondary_range_name
    services_secondary_range_name = local.svc_secondary_range_name
  }

  workload_identity_config {
    identity_namespace = "${module.project.project_id}.svc.id.goog"
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  node_config {
    service_account = google_service_account.cluster_identity.email
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_project_iam_member.cluster_project_permissions
  ]
}

resource "google_container_node_pool" "default" {
  provider   = google-beta
  project    = module.project.project_id
  name       = "${google_container_cluster.default.name}-nodes"
  cluster    = google_container_cluster.default.name
  location   = var.region
  node_count = 1

  node_config {
    image_type   = "cos_containerd"
    machine_type = var.node_machine_type

    service_account = google_service_account.cluster_identity.email

    metadata = {
      disable-legacy-endpoints = true
    }

    disk_size_gb = 100
    disk_type    = "pd-ssd"
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_project_iam_member.cluster_project_permissions
  ]
}