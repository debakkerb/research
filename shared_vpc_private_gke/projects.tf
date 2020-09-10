# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Host project
module "gke_host_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.0"

  name                 = "${var.project_prefix}-host"
  random_project_id    = true
  org_id               = var.organization_id
  folder_id            = var.folder_id
  billing_account      = var.billing_account_id
  skip_gcloud_download = true

  activate_apis = [
    "container.googleapis.com"
  ]
}

## Service projects
module "gke_svc_one" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.0"

  name                 = "${var.project_prefix}-svc-1"
  random_project_id    = true
  org_id               = var.organization_id
  billing_account      = var.billing_account_id
  folder_id            = var.folder_id
  skip_gcloud_download = true

  activate_apis = [
    "container.googleapis.com"
  ]
}

module "gke_svc_two" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.0"

  name                 = "${var.project_prefix}-svc-2"
  random_project_id    = true
  org_id               = var.organization_id
  billing_account      = var.billing_account_id
  folder_id            = var.folder_id
  skip_gcloud_download = true

  activate_apis = [
    "container.googleapis.com"
  ]
}