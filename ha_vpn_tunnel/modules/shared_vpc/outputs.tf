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

output "host_project_id" {
  value = module.host_project.project_id
}

output "service_project_id" {
  value = module.service_project.project_id
}

output "network_selflink" {
  value = google_compute_network.default.self_link
}

output "subnet_one_selflink" {
  value = google_compute_subnetwork.region_one.self_link
}

output "subnet_two_selflink" {
  value = google_compute_subnetwork.region_two.self_link
}

output "subnet_one_name" {
  value = google_compute_subnetwork.region_one.name
}

output "subnet_two_name" {
  value = google_compute_subnetwork.region_two.name
}