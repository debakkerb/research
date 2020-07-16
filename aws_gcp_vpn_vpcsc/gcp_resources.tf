locals {
  project_services = [
    "compute.googleapis.com"
  ]
}

resource "random_pet" "randomizer" {}

resource "google_project" "gcp_project" {
  folder_id       = var.parent_folder_id
  name            = var.gcp_project_name
  project_id      = "${var.gcp_project_name}-${random_pet.randomizer.id}"
  billing_account = var.billing_account_id
}

resource "google_project_service" "project_services" {
  for_each = toset(local.project_services)
  project  = google_project.gcp_project.project_id
  service  = each.value
}

resource "google_compute_network" "connectivity_vpc" {
  project                 = google_project.gcp_project.project_id
  name                    = "conn-network"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.project_services]
}

resource "google_compute_subnetwork" "connectivity_subnet" {
  project                  = google_project.gcp_project.project_id
  ip_cidr_range            = "10.100.0.0/16"
  name                     = "conn-sn"
  network                  = google_compute_network.connectivity_vpc.self_link
  private_ip_google_access = true
  region                   = "europe-west2"
  depends_on               = [google_project_service.project_services]
}

resource "google_service_account" "storage_access" {
  project      = google_project.gcp_project.project_id
  account_id   = "sa-tst-access"
  display_name = "Test Access"
  description  = "Service Account to test access to services across platforms."
}

resource "google_project_iam_member" "sa_access_roles" {
  project = google_project.gcp_project.project_id
  member  = "serviceAccount:${google_service_account.storage_access.email}"
  role    = "roles/owner"
}

resource "google_storage_bucket" "test_bucket" {
  project  = google_project.gcp_project.project_id
  name     = "sc-conn-tst-bckt"
  location = "EU"
}