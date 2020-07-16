provider "google" {}
provider "google-beta" {}

locals {
  project_id = "audit-sink-${random_pet.randomizer.id}"
  project_services = [
    "bigquery.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com"
  ]
}

resource "random_pet" "randomizer" {}

resource "google_project" "audit_sink_project" {
  name                = local.project_id
  project_id          = local.project_id
  auto_create_network = false
  billing_account     = var.billing_account
  org_id              = var.organization_id
  folder_id           = var.folder_id
}

resource "google_project_service" "enabled_service" {
  for_each = toset(local.project_services)
  project  = google_project.audit_sink_project.project_id
  service  = each.value

  disable_dependent_services = true
  disable_on_destroy = true
}

resource "google_resource_manager_lien" "audit_project_lien" {
  origin       = "created-by-terraform"
  parent       = "projects/${google_project.audit_sink_project.number}"
  restrictions = ["resourcemanager.projects.delete"]
  reason       = "Audit log project."
}

# Create GCS bucket and BigQuery dataset
resource "google_storage_bucket" "audit_sink" {
  project = google_project.audit_sink_project.project_id
  name    = "${local.project_id}-audit"
}

resource "google_bigquery_dataset" "audit_sink" {
  project     = google_project.audit_sink_project.project_id
  dataset_id  = "admin_audit_set"
  description = "Dataset to store audit logs for the organization."
}

# Organization sink
resource "google_logging_organization_sink" "bq_admin_logs" {
  org_id           = var.organization_id
  name             = "bq-admin-logs"
  destination      = "bigquery.googleapis.com/${google_bigquery_dataset.audit_sink.id}"
  include_children = true
  filter           = "logName=organizations/${var.organization_id}/logs/cloudaudit.googleapis.com%2Factivity AND NOT protoPayload.authenticationInfo.principalEmail:serviceaccount.com"
}

resource "google_logging_organization_sink" "gcs_admin_logs" {
  org_id           = var.organization_id
  name             = "gcs-admin-logs"
  destination      = "storage.googleapis.com/${google_storage_bucket.audit_sink.name}"
  include_children = true
  filter           = "logName=organizations/${var.organization_id}/logs/cloudaudit.googleapis.com%2Factivity OR organizations/${var.organization_id}/logs/cloudaudit.googleapis.com%2Fdata_access OR organizations/${var.organization_id}/logs/cloudaudit.googleapis.com%2Fsystem_event"
}

# IAM Permissions
resource "google_project_iam_member" "gcs_writer" {
  project = google_project.audit_sink_project.project_id
  member  = google_logging_organization_sink.gcs_admin_logs.writer_identity
  role    = "roles/storage.objectCreator"
}

resource "google_project_iam_member" "bq_writer" {
  project = google_project.audit_sink_project.project_id
  member  = google_logging_organization_sink.bq_admin_logs.writer_identity
  role    = "roles/bigquery.dataEditor"
}
