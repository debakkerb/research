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

output "get_credentials" {
  value = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${module.default.project_id}"
}

output "artifact_registry_image_name" {
  value = "${var.region}-docker.pkg.dev/${module.default.project_id}/${google_artifact_registry_repository.default.name}/flink-cluster"
}

output "workload_identity" {
  value = google_service_account.workload_identity.email
}