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

output "backend_bucket_name" {
  value = google_compute_backend_bucket.backend.name
}

output "cdn_secret_name" {
  value = google_secret_manager_secret.cdn_signing_key.name
}

output "cdn_sign_key_name" {
  value = google_compute_backend_bucket_signed_url_key.signed_key.name
}

output "image_name" {
  value = local.full_image_name
}

output "load_balancer_ip_address" {
  value = google_compute_global_address.https_lb_ip_address.address
}

output "project_id" {
  value = module.project.project_id
}

output "ssl_certificate_name" {
  value = google_compute_managed_ssl_certificate.lb_ssl_certificate.name
}