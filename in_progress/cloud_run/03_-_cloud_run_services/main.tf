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
  pubsub_invoker_iam_permissions = [
    "roles/run.invoker",
    "roles/iam.serviceAccountTokenCreator"
  ]

  pubsub_service_account = "service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  pubsub_service_account_permissions = [
    "roles/iam.serviceAccountTokenCreator"
  ]

  cloud_run_agent = "service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
  cloud_run_agent_permissions = [
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/automl.admin"
  ]

  storage_bucket_agent = "service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
  storage_bucket_agent_permissions = [
    "roles/pubsub.publisher"
  ]
}

data "google_project" "project" {
  project_id = data.terraform_remote_state.infrastructure_backend.outputs.project_id
}

resource "google_pubsub_topic" "process_topic" {
  project = data.google_project.project.project_id
  name    = "process-images-topic"
}

resource "google_service_account" "pubsub_invoker_identity" {
  project      = data.google_project.project.project_id
  account_id   = "cloud-run-pubsub-invoker"
  display_name = "Cloud Run Pub/Sub Invoker"
}

resource "google_project_iam_member" "pubsub_invoker_identity_permissions" {
  for_each = toset(local.pubsub_invoker_iam_permissions)
  project  = data.google_project.project.project_id
  member   = "serviceAccount:${google_service_account.pubsub_invoker_identity.email}"
  role     = each.value
}

resource "google_project_iam_member" "cloud_run_iam_permissions" {
  for_each = toset(local.cloud_run_agent_permissions)
  project  = data.google_project.project.project_id
  member   = "serviceAccount:${local.cloud_run_agent}"
  role     = each.value
}

resource "google_service_account" "workload_identity" {
  project      = data.google_project.project.project_id
  account_id   = "image-analysis-run-id"
  display_name = "Cloud Run Workload Identity"
  description  = "Identity that is used by the Cloud Run workload to access Cloud Vision API."
}

resource "google_project_iam_member" "workload_identity_permissions" {
  for_each = toset(local.cloud_run_agent_permissions)
  project  = data.google_project.project.project_id
  member   = "serviceAccount:${google_service_account.workload_identity.email}"
  role     = each.value
}

resource "google_cloud_run_service" "pubsub_subscription" {
  project  = data.google_project.project.project_id
  name     = "image-blur"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.workload_identity.email
      containers {
        image = "${var.region}-docker.pkg.dev/${data.google_project.project.project_id}/${data.terraform_remote_state.infrastructure_backend.outputs.artifact_registry_name}/image-processing:v2.0.1"
        env {
          name  = "BLURRED_BUCKET_NAME"
          value = data.terraform_remote_state.infrastructure_backend.outputs.output_bucket_name
        }
      }

    }

  }

  depends_on = [
    google_project_iam_member.cloud_run_iam_permissions
  ]
}

resource "google_project_iam_member" "pubsub_permissions" {
  for_each = toset(local.pubsub_service_account_permissions)
  project  = data.google_project.project.project_id
  member   = "serviceAccount:${local.pubsub_service_account}"
  role     = each.value
}

resource "google_pubsub_subscription" "pubsub_invoker_subscription" {
  project = data.terraform_remote_state.infrastructure_backend.outputs.project_id
  name    = "myRunSubscription"
  topic   = google_pubsub_topic.process_topic.name

  push_config {
    push_endpoint = google_cloud_run_service.pubsub_subscription.status.0.url
    oidc_token {
      service_account_email = google_service_account.pubsub_invoker_identity.email
    }
  }

  depends_on = [
    google_project_iam_member.pubsub_permissions
  ]
}

resource "google_pubsub_topic_iam_member" "storage_access" {
  for_each = toset(local.storage_bucket_agent_permissions)
  project  = data.google_project.project.project_id
  member   = "serviceAccount:${local.storage_bucket_agent}"
  role     = each.value
  topic    = google_pubsub_topic.process_topic.name
}

resource "google_storage_notification" "image_upload" {
  bucket         = data.terraform_remote_state.infrastructure_backend.outputs.input_bucket_name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.process_topic.id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [
    google_pubsub_topic_iam_member.storage_access
  ]
}