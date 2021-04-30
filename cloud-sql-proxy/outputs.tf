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

output "start_ssh_tunnel" {
  value = "gcloud compute ssh ${google_compute_instance.proxy_instance.name} --project ${module.cloud_sql_proxy_service_project.project_id}"
}

output "sql_instance_connection_name" {
  value = google_sql_database_instance.private_sql_instance.connection_name
}

output "start_iap_tunnel" {
  value = "gcloud compute start-iap-tunnel ${google_compute_instance.proxy_instance.name} 5432 --local-host-port=localhost:5432 --zone ${google_compute_instance.proxy_instance.zone} --project ${module.cloud_sql_proxy_service_project.project_id}"
}

output "sql_client_command" {
  value = "psql \"host=127.0.0.1 sslmode=disable dbname=${google_sql_database.records_db.name} user=${google_sql_user.user_dev_access.name}\""
}

output "host_network_project_id" {
  value = module.cloud_sql_proxy_host_project.project_id
}

output "service_network_project_id" {
  value = module.cloud_sql_proxy_service_project.project_id
}