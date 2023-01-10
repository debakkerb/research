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

resource "google_dns_managed_zone" "dns_zone_network_one" {
  project     = module.vpn_project.project_id
  name        = "dns-zone-network-1"
  dns_name    = "network-one-hosts.com."
  description = "DNS resolution for network one."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.network_one.id
    }
  }
}

resource "google_dns_record_set" "dns_record_vm_one" {
  project      = module.vpn_project.project_id
  name         = "one.${google_dns_managed_zone.dns_zone_network_one.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dns_zone_network_one.name
  rrdatas      = [google_compute_instance.vm_one.network_interface[0].network_ip]
}

resource "google_dns_managed_zone" "dns_zone_network_two" {
  project     = module.vpn_project.project_id
  name        = "dns-zone-network-2"
  dns_name    = "network-two-hosts.com."
  description = "DNS resolution for network two."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.network_two.id
    }
  }
}

resource "google_dns_record_set" "dns_record_vm_two" {
  project      = module.vpn_project.project_id
  name         = "two.${google_dns_managed_zone.dns_zone_network_two.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dns_zone_network_two.name
  rrdatas      = [google_compute_instance.vm_two.network_interface[0].network_ip]
}

resource "google_dns_managed_zone" "dns_zone_peer_two_one" {
  project     = module.vpn_project.project_id
  name        = "dns-zone-peer-network-2-1"
  description = "DNS Peering zone between network 2 and network 1"
  visibility  = "private"
  dns_name    = "network-one-hosts.com."

  private_visibility_config {
    networks {
      network_url = google_compute_network.network_two.id
    }
  }

  peering_config {
    target_network {
      network_url = google_compute_network.network_one.id
    }
  }
}

resource "google_dns_managed_zone" "dns_zone_peer_one_two" {
  project     = module.vpn_project.project_id
  name        = "dns-zone-peer-network-1-2"
  description = "DNS Peering zone between network 1 and network 2"
  visibility  = "private"
  dns_name    = "network-two-hosts.com."

  private_visibility_config {
    networks {
      network_url = google_compute_network.network_one.id
    }
  }

  peering_config {
    target_network {
      network_url = google_compute_network.network_two.id
    }
  }
}
