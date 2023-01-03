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
  host_gke_robot_sa  = "service-${module.gke_host_project.project_number}@container-engine-robot.iam.gserviceaccount.com"
  service_1_robot_sa = "service-${module.gke_svc_one.project_number}@container-engine-robot.iam.gserviceaccount.com"
  service_2_robot_sa = "service-${module.gke_svc_two.project_number}@container-engine-robot.iam.gserviceaccount.com"

  google_api_svc1_sa = "${module.gke_svc_one.project_number}@cloudservices.gserviceaccount.com"
  google_api_svc2_sa = "${module.gke_svc_two.project_number}@cloudservices.gserviceaccount.com"

  gke_operator_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
}

resource "random_id" "randomizer" {
  byte_length = 4
}

## Host project
module "gke_host_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = "${var.prefix}-host"
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "container.googleapis.com"
  ]
}

## Service projects
module "gke_svc_one" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name                 = "${var.prefix}-svc-1"
  random_project_id    = true
  org_id               = var.organization_id
  billing_account      = var.billing_account_id
  folder_id            = var.folder_id

  activate_apis = [
    "container.googleapis.com"
  ]
}

module "gke_svc_two" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name                 = "${var.prefix}-svc-2"
  random_project_id    = true
  org_id               = var.organization_id
  billing_account      = var.billing_account_id
  folder_id            = var.folder_id

  activate_apis = [
    "container.googleapis.com"
  ]
}