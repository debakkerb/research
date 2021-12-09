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

resource "google_storage_bucket" "input" {
  project                     = module.gke_run_demo_project.project_id
  name                        = "bdb-gke-run-demo-input"
  force_destroy               = true
  uniform_bucket_level_access = true
  location                    = "europe-west1"
}

resource "google_storage_bucket" "output" {
  project                     = module.gke_run_demo_project.project_id
  name                        = "bdb-gke-run-demo-output"
  force_destroy               = true
  uniform_bucket_level_access = true
  location                    = "europe-west1"
}

