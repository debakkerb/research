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

resource "google_service_account" "sql_proxy_service_account" {
  project     = module.cloud_sql_proxy_service_project.project_id
  account_id  = "sql-proxy-vm-id"
  description = "Service account, attached to the VM running the SQL proxy."
}

resource "google_service_account_iam_member" "sql_proxy_sa_access" {
  member             = "user:${var.identity}"
  role               = "roles/iam.serviceAccountUser"
  service_account_id = google_service_account.sql_proxy_service_account.id
}

resource "google_project_iam_member" "id_iap_access" {
  project = module.cloud_sql_proxy_service_project.project_id
  member  = "user:${var.identity}"
  role    = "roles/iap.tunnelResourceAccessor"
}

resource "google_project_iam_member" "cloud_sql_user" {
  project = module.cloud_sql_proxy_service_project.project_id
  member  = "serviceAccount:${google_service_account.sql_proxy_service_account.email}"
  role    = "roles/cloudsql.instanceUser"
}