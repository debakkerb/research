
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

resource "random_string" "tunnel_one_secret" {
  length  = 32
  special = true
}

resource "random_string" "tunnel_two_secret" {
  length  = 32
  special = true
}

resource "google_compute_ha_vpn_gateway" "vpn_gateway_one" {
  project = module.vpn_project.project_id
  name    = var.vpn_gateway_one_name
  region  = var.vpn_gateway_region
  network = google_compute_network.network_one.name
}

resource "google_compute_ha_vpn_gateway" "vpn_gateway_two" {
  project = module.vpn_project.project_id
  name    = var.vpn_gateway_two_name
  region  = var.vpn_gateway_region
  network = google_compute_network.network_two.name
}

// Tunnel VPN Gateway - Tunnel 1, going from Cloud Router 1 (interface 0) to Cloud Router 2 (interface 0)
resource "google_compute_vpn_tunnel" "vpn_gateway_tunnel_10_20" {
  project               = module.vpn_project.project_id
  name                  = var.vpn_tunnel_one_name
  vpn_gateway           = google_compute_ha_vpn_gateway.vpn_gateway_one.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpn_gateway_two.id
  region                = var.vpn_gateway_region
  shared_secret         = random_string.tunnel_one_secret.result
  router                = google_compute_router.network_one_router.id
  vpn_gateway_interface = 0
}

// Reverse tunnel, going from Cloud Router 2 (interface 0) to Cloud Router 1 (interface 0)
resource "google_compute_vpn_tunnel" "vpn_gateway_tunnel_20_10" {
  project               = module.vpn_project.project_id
  name                  = var.vpn_tunnel_three_name
  vpn_gateway           = google_compute_ha_vpn_gateway.vpn_gateway_two.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpn_gateway_one.id
  region                = var.vpn_gateway_region
  shared_secret         = random_string.tunnel_one_secret.result
  router                = google_compute_router.network_two_router.id
  vpn_gateway_interface = 0
}

// Tunnel VPN Gateway - Tunnel 2, going from Cloud Router 1 (interface 1) to Cloud Router 2 (interface 1)
resource "google_compute_vpn_tunnel" "vpn_gateway_tunnel_11_21" {
  project               = module.vpn_project.project_id
  name                  = var.vpn_tunnel_two_name
  vpn_gateway           = google_compute_ha_vpn_gateway.vpn_gateway_one.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpn_gateway_two.id
  region                = var.vpn_gateway_region
  shared_secret         = random_string.tunnel_one_secret.result
  router                = google_compute_router.network_one_router.id
  vpn_gateway_interface = 1
}

// Reverse tunnel, going from Cloud Router 2 (interface 1) to Cloud Router 1 (interface 1)
resource "google_compute_vpn_tunnel" "vpn_gateway_tunnel_21_11" {
  project               = module.vpn_project.project_id
  name                  = var.vpn_tunnel_four_name
  vpn_gateway           = google_compute_ha_vpn_gateway.vpn_gateway_two.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpn_gateway_one.id
  region                = var.vpn_gateway_region
  shared_secret         = random_string.tunnel_one_secret.result
  router                = google_compute_router.network_two_router.id
  vpn_gateway_interface = 1
}

// Router interface
// Cloud Router 1 - VPN tunnel 1 - CR 1/0 to CR 2/0
resource "google_compute_router_interface" "tunnel_one_interface_zero" {
  project    = module.vpn_project.project_id
  name       = var.tunnel_one_interface_name
  router     = google_compute_router.network_one_router.name
  region     = var.vpn_gateway_region
  ip_range   = var.tunnel_one_interface_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.vpn_gateway_tunnel_10_20.name
}

resource "google_compute_router_interface" "tunnel_two_interface_one" {
  project    = module.vpn_project.project_id
  name       = var.tunnel_two_interface_name
  router     = google_compute_router.network_one_router.name
  region     = var.vpn_gateway_region
  ip_range   = var.tunnel_two_interface_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.vpn_gateway_tunnel_11_21.name
}

resource "google_compute_router_interface" "tunnel_three_interface_zero" {
  project    = module.vpn_project.project_id
  name       = var.tunnel_three_interface_name
  router     = google_compute_router.network_two_router.name
  region     = var.vpn_gateway_region
  ip_range   = var.tunnel_three_interface_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.vpn_gateway_tunnel_20_10.name
}

resource "google_compute_router_interface" "tunnel_four_interface_one" {
  project    = module.vpn_project.project_id
  name       = var.tunnel_four_interface_name
  router     = google_compute_router.network_two_router.name
  region     = var.vpn_gateway_region
  ip_range   = var.tunnel_four_interface_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.vpn_gateway_tunnel_21_11.name
}

//  BGP Peering
resource "google_compute_router_peer" "router_one_interface_zero" {
  project                   = module.vpn_project.project_id
  name                      = var.router_one_interface_zero_peer_name
  region                    = var.vpn_gateway_region
  peer_ip_address           = var.router_one_interface_one_peer_ip_address
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel_one_interface_zero.name
  router                    = google_compute_router.network_one_router.name
}

resource "google_compute_router_peer" "router_one_interface_one" {
  project                   = module.vpn_project.project_id
  name                      = var.router_one_interface_one_peer_name
  region                    = var.vpn_gateway_region
  peer_ip_address           = var.router_one_interface_two_peer_ip_address
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel_two_interface_one.name
  router                    = google_compute_router.network_one_router.name
}

resource "google_compute_router_peer" "router_two_interface_zero" {
  project                   = module.vpn_project.project_id
  name                      = var.router_two_interface_zero_peer_name
  region                    = var.vpn_gateway_region
  peer_ip_address           = var.router_two_interface_zero_peer_ip_address
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel_three_interface_zero.name
  router                    = google_compute_router.network_two_router.name
}

resource "google_compute_router_peer" "router_two_interface_one" {
  project                   = module.vpn_project.project_id
  name                      = var.router_two_interface_one_peer_name
  region                    = var.vpn_gateway_region
  peer_ip_address           = var.router_two_interface_one_peer_ip_address
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel_four_interface_one.name
  router                    = google_compute_router.network_two_router.name
}
