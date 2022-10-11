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

module "bootstrap_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = "${var.prefix}-bootstrap"
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.parent_folder_id
  billing_account   = var.billing_account_id
}

resource "google_storage_bucket" "terraform_remote_state_storage" {
  project                     = module.bootstrap_project.project_id
  name                        = "${var.prefix}-impers-state"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 5
    }
  }
}

resource "local_file" "backend_configuration" {
  filename = "${path.module}/backend.tf"
  content = templatefile("${path.module}/backend.tf.tpl", {
    bucket_name                     = google_storage_bucket.terraform_remote_state_storage.name
    prefix                          = "terraform/state/bootstrap"
    bootstrap_service_account_email = google_service_account.orchestrator.email
  })
}