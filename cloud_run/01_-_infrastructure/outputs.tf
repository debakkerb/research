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

output "terraform_state_bucket_name" {
  value = google_storage_bucket.terraform_state_bucket.name
}

output "input_bucket_name" {
  value = google_storage_bucket.input.name
}

output "output_bucket_name" {
  value = google_storage_bucket.output.name
}

output "artifact_registry_name" {
  value = google_artifact_registry_repository.default.name
}

output "project_id" {
  value = module.gke_run_demo_project.project_id
}