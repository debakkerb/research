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
  cloudbuild_default_sa = "${module.gke_run_demo_project.project_number}@cloudbuild.gserviceaccount.com"

  cloudbuild_sa_permissions = [
    "roles/storage.admin",
    "roles/compute.admin",
    "roles/artifactregistry.admin",
    "roles/source.admin",
    "roles/logging.admin",
    "roles/container.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/run.admin",
    "roles/owner"
  ]
}

resource "google_project_iam_member" "cloudbuild_project_permissions" {
  for_each = toset(local.cloudbuild_sa_permissions)
  project  = module.gke_run_demo_project.project_id
  member   = "serviceAccount:${local.cloudbuild_default_sa}"
  role     = each.value
}

module "terraform_builder" {
  source          = "../99_-_modules/terraform_builder"
  project_id      = module.gke_run_demo_project.project_id
  region          = var.region
  repository_name = google_artifact_registry_repository.default.name
}

resource "google_cloudbuild_trigger" "repo_trigger" {
  project     = module.gke_run_demo_project.project_id
  name        = "repo-trigger"
  description = "Cloud Build trigger for the repository code."
  filename    = "cloudbuild.yaml"

  trigger_template {
    repo_name   = google_sourcerepo_repository.source_repo.name
    branch_name = "^main$"
  }

  substitutions = {
    _REGION        = var.region
    _REGISTRY_NAME = google_artifact_registry_repository.default.name
  }
}