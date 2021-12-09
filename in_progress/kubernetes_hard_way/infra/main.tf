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
  project_name = "bdb-k8s-hard-way"
}

resource "random_id" "random_id" {
  byte_length = 2
}

resource "google_project" "kubernetes_hard_way_project" {
  name                = format("%s-%s", local.project_name, random_id.random_id.hex)
  project_id          = format("%s-%s", local.project_name, random_id.random_id.hex)
  billing_account     = var.billing_account_id
  folder_id           = var.folder_id
  auto_create_network = false
}

resource "google_project_service" "compute" {
  project                    = google_project.kubernetes_hard_way_project.project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}

resource "google_compute_network" "default" {
  project                 = google_project.kubernetes_hard_way_project.project_id
  name                    = "kubernetes-the-hard-way"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  project                  = google_project.kubernetes_hard_way_project.project_id
  ip_cidr_range            = "10.240.0.0/16"
  name                     = "kubernetes"
  network                  = google_compute_network.default.self_link
  region                   = "europe-west1"
  private_ip_google_access = true
}

resource "google_compute_firewall" "internal_comms" {
  project = google_project.kubernetes_hard_way_project.project_id
  name    = "kubernetes-the-hard-way-allow-internal"
  network = google_compute_network.default.self_link

  source_ranges = [
    "10.240.0.0/24,10.200.0.0/16"
  ]

  allow {
    protocol = "tcp,udp,icmp"
  }
}

resource "google_compute_firewall" "external_comms" {
  project = google_project.kubernetes_hard_way_project.project_id
  name    = "kubernetes-the-hard-way-allow-external"
  network = google_compute_network.default.self_link

  allow {
    protocol = "tcp:22,tcp6443,icmp"
  }

  source_ranges = [
    "0.0.0.0/0"
  ]
}

resource "google_compute_address" "public_ip" {
  project      = google_project.kubernetes_hard_way_project.project_id
  name         = "kubernetes-the-hard-way"
  region       = "europe-west1"
  address_type = "EXTERNAL"
}