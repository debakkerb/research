/**
 * Copyright 2022 Google LLC
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

resource "google_iap_brand" "project_brand" {
  project           = module.project.project_id
  application_title = var.brand_application_title
  support_email     = var.brand_support_email
}

resource "google_iap_client" "project_oauth_client" {
  brand        = google_iap_brand.project_brand.name
  display_name = var.iap_client_display_name
}