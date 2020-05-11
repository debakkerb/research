/**
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
  function_project_id = "function-project-${random_id.randomizer.hex}"

  function_project_services = [
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "appengine.googleapis.com",
    "vpcaccess.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

resource "google_project" "private_function_project" {
  name       = local.function_project_id
  project_id = local.function_project_id

  billing_account = var.billing_account
  org_id          = local.org_id
  folder_id       = local.folder_id
}

resource "google_project_service" "function_project_services" {
  for_each = toset(local.function_project_services)

  project = google_project.private_function_project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = true
}

resource "google_compute_network" "private_function_network" {
  project = google_project.private_function_project.project_id

  name                    = "function-network"
  auto_create_subnetworks = false

  depends_on = [google_project_service.function_project_services]
}

resource "google_compute_subnetwork" "private_function_subnet" {
  project = google_project.private_function_project.project_id

  ip_cidr_range = "10.200.0.0/26"
  name          = "function-snw"
  network       = google_compute_network.private_function_network.self_link
  region        = "europe-west1"
}

resource "google_storage_bucket" "cloud_function_source_bucket" {
  project = google_project.private_function_project.project_id

  name = "fnc-ping-${random_id.randomizer.hex}"
  versioning {
    enabled = true
  }

  force_destroy = true
}

data "archive_file" "healthcheck_file" {
  source_dir  = "${path.root}/healthcheck"
  output_path = "${path.root}/healthcheck.zip"
  type        = "zip"
}

resource "google_storage_bucket_object" "cloud_function_source" {
  bucket = google_storage_bucket.cloud_function_source_bucket.name
  name   = "healthcheck.zip"
  source = data.archive_file.healthcheck_file.output_path
}

resource "google_pubsub_topic" "private_function_trigger" {
  project = google_project.private_function_project.project_id
  name    = "healthcheck-trigger"
}

resource "google_cloudfunctions_function" "healthcheck" {
  project = google_project.private_function_project.project_id

  name                = "healthcheck"
  description         = "Cloud Function to run a healthcheck"
  available_memory_mb = 128
  timeout             = 60

  source_archive_bucket = google_storage_bucket.cloud_function_source_bucket.name
  source_archive_object = google_storage_bucket_object.cloud_function_source.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${google_project.private_function_project.project_id}/topics/${google_pubsub_topic.private_function_trigger.name}"
  }

  vpc_connector = "projects/${google_project.private_function_project.project_id}/locations/europe-west1/connectors/${google_vpc_access_connector.private_connector.name}"

  region  = "europe-west1"
  runtime = "go"
}

resource "google_project_iam_member" "fnc_network_user" {
  project = google_project.private_function_project.project_id
  member  = "serviceAccount:service-${google_project.private_function_project.number}@gcf-admin-robot.iam.gserviceaccount.com"
  role    = "roles/compute.networkUser"

  depends_on = [google_project_service.function_project_services]
}

resource "google_vpc_access_connector" "private_connector" {
  project       = google_project.private_function_project.project_id
  name          = "connector"
  region        = "europe-west1"
  ip_cidr_range = local.private_connector_cidr
  network       = google_compute_network.private_function_network.name
}

resource "google_cloud_scheduler_job" "scheduled_healthcheck_job" {
  project = google_project.private_function_project.project_id

  name        = "healthcheck-scheduler-job"
  description = "Scheduler to trigger healthcheck."
  schedule    = "15 * * * *"
  region      = "europe-west1"

  pubsub_target {
    topic_name = google_pubsub_topic.private_function_trigger.id
    data       = base64encode("check")
  }

  depends_on = [
    google_app_engine_application.scheduler_app
  ]
}

resource "google_app_engine_application" "scheduler_app" {
  project     = google_project.private_function_project.project_id
  location_id = "europe-west"
}




