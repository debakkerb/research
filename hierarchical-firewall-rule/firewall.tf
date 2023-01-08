/**
 * Copyright 2023 Google LLC
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

resource "random_id" "default" {
  byte_length = 2
}

resource "google_compute_firewall_policy" "default" {
  parent      = var.parent
  short_name  = "${var.policy_short_name}-${random_id.default.hex}"
  description = "Firewall policy for this organization"
}

resource "google_compute_firewall_policy_rule" {
  firewall_policy = google_compute_firewall_policy.default.id
  description     = "Firewall policy to block all incoming traffic on 0.0.0.0/0"
  priority        = 9000
  enable_logging  = true
  action          = "deny"
  direction       = "INGRESS"
  disabled        = false

  match {
    layer_4_configs {
      ip_protocol = "tcp"
      ports       = [80, 8080]
    }
  }

  dest_ranges = "10.0.0.0/16"
}

data "google_folder" "folder" {
  folder = "folders/${var.folder_id}"
}

resource "google_compute_firewall_policy_association" "default" {
  firewall_policy   = google_compute_firewall_policy.default.id
  attachment_target = data.google_folder.folder.name
  name              = "fw-policy-association-${random_id.default.hex}"
}

