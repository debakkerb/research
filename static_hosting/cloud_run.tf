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

resource "google_service_account" "service_identity" {
  project    = module.default.project_id
  account_id = "static-host-svc-id"
}

resource "google_cloud_run_service" "login_service" {
  project  = module.default.project_id
  name     = var.login_service_name
  location = var.region

  autogenerate_revision_name = true

  template {
    spec {
      service_account_name = google_service_account.service_identity.email
      containers {
        image = "${local.full_image_name}:${local.image_tag}"
      }
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  depends_on = [
    module.login_app_image
  ]
}

data "google_iam_policy" "allow_no_auth" {
  binding {
    members = ["allUsers"]
    role    = "roles/run.invoker"
  }
}

resource "google_cloud_run_service_iam_policy" "allow_no_auth_policy" {
  project     = module.default.project_id
  location    = var.region
  policy_data = data.google_iam_policy.allow_no_auth.policy_data
  service     = google_cloud_run_service.login_service.name
}

resource "google_iap_web_iam_member" "cloud_run_access" {
  for_each = var.login_service_access
  project  = module.default.project_id
  member   = each.value
  role     = "roles/iap.httpsResourceAccessor"
}