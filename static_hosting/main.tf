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

module "project" {
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
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "google_project_iam_member" "project_viewers" {
  for_each = var.project_viewers
  project  = module.project.project_id
  member   = each.value
  role     = "roles/viewer"
}

resource "google_storage_bucket" "static_asset_storage_bucket" {
  project                     = module.project.project_id
  name                        = "${module.project.project_id}-static-hosting"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "403.html"
  }

  cors {
    origin          = var.cors_origin
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_object" "modules" {
  for_each = var.upload_sample_content ? toset(["one", "two"]) : []
  name     = "module_${each.value}/index.html"
  bucket   = google_storage_bucket.static_asset_storage_bucket.name

  content = templatefile("${path.module}/static/sample_index.html", {
    NAME = each.value
  })
}

resource "google_storage_bucket_object" "index_page" {
  bucket = google_storage_bucket.static_asset_storage_bucket.name
  name   = "index.html"
  source = "${path.module}/static/index.html"
}

resource "google_storage_bucket_object" "not_found_page" {
  bucket = google_storage_bucket.static_asset_storage_bucket.name
  name   = "403.html"
  source = "${path.module}/static/403.html"
}

resource "google_storage_bucket_iam_member" "cdn_access" {
  bucket = google_storage_bucket.static_asset_storage_bucket.name
  member = "serviceAccount:service-${module.project.project_number}@cloud-cdn-fill.iam.gserviceaccount.com"
  role   = "roles/storage.objectViewer"

  depends_on = [
    google_compute_backend_bucket_signed_url_key.signed_key
  ]
}