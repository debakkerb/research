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
  pod_secondary_range_name = "${var.prefix}-pod-range"
  svc_secondary_range_name = "${var.prefix}-svc-range"

  cluster_identity_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.admin"
  ]

  workload_identity_roles = [
    "roles/trafficdirector.client"
  ]
}

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = var.prefix
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "container.googleapis.com",
    "trafficdirector.googleapis.com"
  ]
}

resource "google_compute_network" "network" {
  project                 = module.project.project_id
  name                    = "${var.prefix}-td-tst-nw"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  project                  = module.project.project_id
  ip_cidr_range            = var.cidr_block
  name                     = "${var.prefix}-td-tst-snw"
  network                  = google_compute_network.network.self_link
  private_ip_google_access = true
  region                   = var.region

  secondary_ip_range {
    range_name    = local.pod_secondary_range_name
    ip_cidr_range = var.pod_cidr_range
  }

  secondary_ip_range {
    range_name    = local.svc_secondary_range_name
    ip_cidr_range = var.service_cidr_range
  }
}

//resource "google_compute_firewall" "proxy_access_master" {
//  project   = module.project.project_id
//  name      = "td-master-access"
//  network   = google_compute_network.network.self_link
//  direction = "INGRESS"
//  source_ranges = [""]
//}

resource "google_service_account" "cluster_identity" {
  project      = module.project.project_id
  account_id   = "${var.prefix}-cluster-id"
  description  = "Identity for the GKE cluster"
  display_name = "Cluster Identity"
}

resource "google_service_account" "workload_identity" {
  project      = module.project.project_id
  account_id   = "${var.prefix}-workload-id"
  description  = "Identity for the sample application deployed on the cluster."
  display_name = "Workload Identity"
}

resource "google_project_iam_member" "cluster_project_permissions" {
  for_each = toset(local.cluster_identity_roles)
  project  = module.project.project_id
  member   = "serviceAccount:${google_service_account.cluster_identity.email}"
  role     = each.value
}

resource "google_project_iam_member" "workload_project_permissions" {
  for_each = toset(local.workload_identity_roles)
  project  = module.project.project_id
  member   = "serviceAccount:${google_service_account.workload_identity.email}"
  role     = each.value
}



