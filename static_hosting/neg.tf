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

resource "google_compute_region_network_endpoint_group" "login_app_endpoint_group" {
  provider              = google-beta
  project               = module.project.project_id
  name                  = "${var.load_balancer_name}-managed-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_service.login_service.name
  }
}

resource "google_compute_backend_service" "login_app_service" {
  project     = module.project.project_id
  name        = "${var.load_balancer_name}-managed-neg-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  log_config {
    enable = var.enable_backend_service_logging
  }

  backend {
    group       = google_compute_region_network_endpoint_group.login_app_endpoint_group.id
    description = "NEG for the CLoud Run service."
  }

  iap {
    oauth2_client_id     = google_iap_client.project_oauth_client.client_id
    oauth2_client_secret = google_iap_client.project_oauth_client.secret
  }
}