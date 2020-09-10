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

resource "google_container_cluster" "gke_cluster" {
  project     = module.gke_svc_one.project_id
  name        = "gke-cluster-one"
  description = "GKE cluster to use for troubleshooting issues."
  location    = "europe-west1"
  network     = google_compute_network.gke_host_network.self_link
  subnetwork  = google_compute_subnetwork.gke_host_subnet_1.self_link

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
    cluster_secondary_range_name  = "gke-pod-euw1-secondary"
    services_secondary_range_name = "gke-svc-euw1-secondary"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "10.255.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = google_compute_subnetwork.gke_host_subnet_1.ip_cidr_range
    }

    cidr_blocks {
      cidr_block = google_compute_subnetwork.gke_host_subnet_2.ip_cidr_range
    }
  }

  node_config {
    service_account = google_service_account.gke_svc1_service_account.email
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring"
    ]
  }

  timeouts {
    create = "10m"
    update = "20m"
  }

  depends_on = [
    google_project_iam_member.host_agent_svc_2,
    google_project_iam_member.host_agent_svc_1,
    google_project_iam_member.gke_svc1_sa_iam_permissions,
    google_project_iam_member.gke_svc1_fwl_permissions,
    google_project_iam_member.gke_svc2_sa_iam_permissions,
    google_project_iam_member.gke_svc2_fwl_permissions,
    google_compute_subnetwork_iam_member.google_api_svc1_host,
    google_compute_subnetwork_iam_member.google_api_svc2_host,
    google_compute_subnetwork_iam_member.service_1_robot_network_user,
    google_compute_subnetwork_iam_member.service_2_robot_network_user,
    google_compute_shared_vpc_host_project.host_project_config,
    google_compute_shared_vpc_service_project.svc_one_attachment,
    google_compute_shared_vpc_service_project.svc_two_attachment,
  ]
}

resource "google_container_node_pool" "gke_node_pool" {
  provider   = google-beta
  project    = module.gke_svc_one.project_id
  name       = "gke-fin-nodes"
  cluster    = google_container_cluster.gke_cluster.name
  location   = "europe-west1"
  node_count = 1

  node_config {
    image_type   = "cos_containerd"
    machine_type = "n2-standard-4"

    service_account = google_service_account.gke_svc1_service_account.email
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    sandbox_config {
      sandbox_type = "gvisor"
    }

    disk_size_gb = 20
    disk_type    = "pd-ssd"
  }

  depends_on = [
    google_project_iam_member.host_agent_svc_2,
    google_project_iam_member.host_agent_svc_1,
    google_project_iam_member.gke_svc1_sa_iam_permissions,
    google_project_iam_member.gke_svc1_fwl_permissions,
    google_project_iam_member.gke_svc2_sa_iam_permissions,
    google_project_iam_member.gke_svc2_fwl_permissions,
    google_compute_subnetwork_iam_member.google_api_svc1_host,
    google_compute_subnetwork_iam_member.google_api_svc2_host,
    google_compute_subnetwork_iam_member.service_1_robot_network_user,
    google_compute_subnetwork_iam_member.service_2_robot_network_user,
    google_compute_shared_vpc_host_project.host_project_config,
    google_compute_shared_vpc_service_project.svc_two_attachment,
    google_compute_shared_vpc_service_project.svc_one_attachment,
  ]
}