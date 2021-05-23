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

resource "google_service_account" "orchestrator" {
  project      = module.bootstrap.project_id
  account_id   = "${local.prefix}orchestrator"
  description  = "Service account to be used by CI/CD pipelines."
  display_name = "Orchestrator"
}
