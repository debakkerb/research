/**
 * Copyright 2023 Google LLC
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

output "network_one_selflink" {
  value = google_compute_network.network_two.self_link
}

output "project_id" {
  value = module.vpn_project.project_id
}

output "ssh_instance_one_command" {
  value = "gcloud compute ssh ${google_compute_instance.vm_one.name} --zone ${google_compute_instance.vm_one.zone} --project ${module.vpn_project.project_id}"
}

output "ssh_instance_two_command" {
  value = "gcloud compute ssh ${google_compute_instance.vm_two.name}  --zone ${google_compute_instance.vm_two.zone} --project ${module.vpn_project.project_id}"
}

