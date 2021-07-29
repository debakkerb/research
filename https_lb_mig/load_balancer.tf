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

resource "google_compute_global_address" "https_lb_ip_address" {
  project      = module.project.project_id
  name         = "${var.prefix}-lb-ip-address"
  ip_version   = "IPV4"
  description  = "IP address for the public Load Balancer."
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "https_lb_fwd_rule" {
  project               = module.project.project_id
  name                  = "${var.prefix}-lb-fwd-rule"
  ip_address            = google_compute_global_address.https_lb_ip_address.address
  target                = google_compute_target_https_proxy.target_proxy.self_link
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_firewall" "gcp_health_check" {
  project     = module.project.project_id
  name        = "lb-mig-access"
  network     = google_compute_network.default.self_link
  description = "Firewall rule to allow health checks from the Google platform."
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [443]
  }

  source_ranges = [
    "130.244.0.0/22",
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = [
    "gke-apigee-proxy"
  ]
}

resource "google_compute_managed_ssl_certificate" "https_lb_managed_certificate" {
  project     = module.project.project_id
  name        = "lb-managed-cert"
  description = "SSL Certificate to be attached to the load balancer."

  managed {
    domains = [var.domain]
  }

}

resource "google_compute_backend_service" "backend_service" {
  project                         = module.project.project_id
  health_checks                   = [google_compute_health_check.mig_healthcheck.self_link]
  name                            = "${var.prefix}-backend"
  load_balancing_scheme           = "EXTERNAL"
  port_name                       = "https"
  protocol                        = "HTTPS"
  session_affinity                = "NONE"
  timeout_sec                     = 60
  connection_draining_timeout_sec = 300

  backend {
    group = google_compute_region_instance_group_manager.default.instance_group
  }
}

resource "google_compute_url_map" "url_map" {
  project         = module.project.project_id
  name            = "${var.prefix}-url-map"
  default_service = google_compute_backend_service.backend_service.self_link
}

resource "google_compute_target_https_proxy" "target_proxy" {
  project          = module.project.project_id
  name             = "${var.prefix}-mig-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.https_lb_managed_certificate.self_link]
  url_map          = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  project               = module.project.project_id
  name                  = "${var.prefix}-be-fwd-rule"
  ip_address            = google_compute_global_address.https_lb_ip_address.address
  target                = google_compute_target_https_proxy.target_proxy.self_link
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}