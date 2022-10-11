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

module "default" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.0"

  name              = var.project_name
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account_id

  activate_apis = [
    "storage.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "iap.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

resource "google_storage_bucket" "default" {
  project                     = module.default.project_id
  name                        = var.storage_bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = var.cors_origin
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_object" "module_one_page" {
  name   = "module_one.html"
  bucket = google_storage_bucket.default.name
  source = "${path.module}/static/module_one.html"
}

resource "google_storage_bucket_object" "module_two_page" {
  name   = "module_two.html"
  bucket = google_storage_bucket.default.name
  source = "${path.module}/static/module_two.html"
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.default.name
  member = "allUsers"
  role   = "roles/storage.objectViewer"
}

resource "google_storage_bucket_iam_member" "cdn_access" {
  bucket = google_storage_bucket.default.name
  member = "serviceAccount:service-${module.default.project_number}@cloud-cdn-fill.iam.gserviceaccount.com"
  role   = "roles/storage.objectViewer"

  depends_on = [
    google_compute_backend_bucket_signed_url_key.signed_key
  ]
}

