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

module "host_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 10.3"

  name              = "${var.prefix}-host"
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.parent_folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "service_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 10.3"

  name              = "${var.prefix}-application"
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.parent_folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "servicenetworking.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}
