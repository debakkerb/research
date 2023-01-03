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

resource "google_service_account_iam_member" "proxy_service_account_access" {
  for_each           = var.proxy_access_identities
  member             = each.value
  role               = "roles/iam.serviceAccountUser"
  service_account_id = google_service_account.sql_proxy_service_account.id
}

resource "google_iap_tunnel_instance_iam_member" "id_iap_access" {
  for_each = var.proxy_access_identities
  project  = module.cloud_sql_proxy_service_project.project_id
  member   = each.value
  role     = "roles/iap.tunnelResourceAccessor"
  instance = google_compute_instance.proxy_instance.name
  zone     = var.zone
}

resource "google_project_iam_member" "cloud_sql_admin" {
  project = module.cloud_sql_proxy_service_project.project_id
  member  = "serviceAccount:${google_service_account.sql_proxy_service_account.email}"
  role    = "roles/cloudsql.client"
}

resource "google_compute_instance_iam_member" "retrieve_and_update_instance_details" {
  for_each      = var.proxy_access_identities
  project       = module.cloud_sql_proxy_service_project.project_id
  instance_name = google_compute_instance.proxy_instance.name
  member        = each.value
  role          = var.create_custom_compute_get_role ? google_project_iam_custom_role.instance_details_role.0.id : "roles/compute.instanceAdmin.v1"
  zone          = var.zone
}

resource "google_project_iam_custom_role" "instance_details_role" {
  count       = var.create_custom_compute_get_role ? 1 : 0
  project     = module.cloud_sql_proxy_service_project.project_id
  permissions = ["compute.instances.get", "compute.instances.setMetadata", "compute.projects.get"]
  role_id     = "computeInstanceDetailsLogin"
  title       = "Compute Instance Details Login"
  description = "Role to retrieve the instances details and to set instance metadata, required for updating SSH keys or RDP passwords and to login via gcloud compute ssh."
}

resource "google_compute_instance_iam_member" "oslogin_admin" {
  for_each      = var.enable_ssh_access ? var.proxy_access_identities : []
  project       = module.cloud_sql_proxy_service_project.project_id
  instance_name = google_compute_instance.proxy_instance.name
  member        = each.value
  role          = "roles/compute.osAdminLogin"
  zone          = var.zone
}
