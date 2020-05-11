locals {
  project_services = [
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]

  organization_id   = var.organization_id == null ? null : var.organization_id
  folder_id         = var.folder_id == null ? null : var.folder_id
  project_id        = "tst-impersonation-${random_string.project_extension.result}"
  target_project_id = "tst-target-${random_string.project_extension.result}"
  cloud_build_sa    = "${google_project.cloud_build_project.number}@cloudbuild.gserviceaccount.com"
}

provider "google" {}
provider "google-beta" {}

resource "random_string" "project_extension" {
  length  = 4
  special = false
  upper   = false
}

resource "google_project" "cloud_build_project" {
  project_id          = local.project_id
  name                = local.project_id
  auto_create_network = false
  billing_account     = var.billing_account
  folder_id           = local.folder_id
  org_id              = local.organization_id
}

resource "google_project_service" "default" {
  for_each                   = toset(local.project_services)
  project                    = google_project.cloud_build_project.project_id
  service                    = each.value
  disable_dependent_services = true
  disable_on_destroy         = true
}

resource "google_service_account" "project_creator" {
  project      = google_project.cloud_build_project.project_id
  account_id   = "sa-project-creator"
  display_name = "Project Creator"
}

resource "google_organization_iam_member" "organization_project_creator" {
  count  = local.organization_id == null ? 0 : 1
  org_id = local.organization_id
  member = "serviceAccount:${google_service_account.project_creator.email}"
  role   = "roles/resourcemanager.projectCreator"
}

resource "google_folder_iam_member" "folder_project_creator" {
  count  = local.folder_id == null ? 0 : 1
  folder = local.folder_id
  member = "serviceAccount:${google_service_account.project_creator.email}"
  role   = "roles/resourcemanager.projectCreator"
}

resource "google_service_account_iam_binding" "sa_cloud_build_impersonator" {
  service_account_id = "projects/${google_project.cloud_build_project.project_id}/serviceAccounts/${google_service_account.project_creator.email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  members = [
    "serviceAccount:${local.cloud_build_sa}",
    "user:${var.user_id}"
  ]

  depends_on = [google_project_service.default]
}

data "google_service_account_access_token" "project_creator_access_token" {
  provider               = google
  scopes                 = ["cloud-platform", "userinfo-email"]
  target_service_account = google_service_account.project_creator.email
  lifetime               = "300s"

  depends_on = [google_service_account_iam_binding.sa_cloud_build_impersonator]
}

provider "google" {
  alias        = "impersonator"
  access_token = data.google_service_account_access_token.project_creator_access_token.access_token
}

provider "google-beta" {
  alias        = "impersonator"
  access_token = data.google_service_account_access_token.project_creator_access_token.access_token
}

resource "google_project" "target_project" {
  provider            = google.impersonator
  name                = local.target_project_id
  project_id          = local.target_project_id
  auto_create_network = false
  folder_id           = local.folder_id
  org_id              = local.organization_id

  depends_on = [data.google_service_account_access_token.project_creator_access_token]
}
