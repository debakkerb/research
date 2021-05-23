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
  prefix = length(var.prefix) != 0 ? "${var.prefix}-" : ""
  service_accounts_alias = [
    "folders",
    "network",
    "security"
  ]
}

module "bootstrap" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 10.3"

  name              = "${local.prefix}bootstrap"
  random_project_id = true
  org_id            = var.organization_id
  billing_account   = var.billing_account_id
}

resource "google_storage_bucket" "terraform_state_bucket" {
  project                     = module.bootstrap.project_id
  name                        = "${local.prefix}tf-state"
  force_destroy               = true
  uniform_bucket_level_access = true
  location                    = var.region

  versioning {
    enabled = true
  }
}

data "template_file" "backend" {
  template = file("${path.module}/backend.tf.tpl")
  vars = {
    gcs_bucket_tf_state             = google_storage_bucket.terraform_state_bucket.name
    tf_state_prefix                 = "terraform/state/bootstrap"
    bootstrap_service_account_email = google_service_account.orchestrator.email
  }
}

resource "local_file" "bootstrap_backend" {
  content  = data.template_file.backend.rendered
  filename = "${path.module}/backend.tf"
}
