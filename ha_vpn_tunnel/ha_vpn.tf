/**
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
# VPN Gateway 1
resource "google_compute_ha_vpn_gateway" "gw_vpc_1" {
  provider = google-beta
  project  = module.project_vpc_1.project_id

  network     = google_compute_network.public_vpc_1.self_link
  name        = "gw-vpc-1"
  description = "VPN Gateway VPC 1."
  region      = "europe-west1"
}

# VPN Gateway
resource "google_compute_ha_vpn_gateway" "gw_vpc_2" {
  provider = google-beta
  project  = module.project_vpc_2.project_id

  network     = google_compute_network.private_vpc_2.self_link
  name        = "gw-vpc-2"
  description = "VPN Gateway VPC 2."
  region      = "europe-west1"
}

# Cloud Routers
resource "google_compute_router" "cr_vpc_1" {
  project = module.project_vpc_1.project_id

  network     = google_compute_network.public_vpc_1.self_link
  name        = "cr-vpc-1"
  description = "Cloud Router VPC1, region europe-west1"
  region      = "europe-west1"

  bgp {
    asn = 65001
  }
}

resource "google_compute_router" "cr_vpc_2" {
  project = module.project_vpc_2.project_id

  network     = google_compute_network.private_vpc_2.self_link
  name        = "cr-vpc-2"
  description = "Cloud Router VPC2, region europe-west1."
  region      = "europe-west1"

  bgp {
    asn = 65002
  }
}

# VPN Tunnels
## Gateway 1, Tunnel 0
resource "google_compute_vpn_tunnel" "vpn_tunnel_gw1_int0" {
  provider = google-beta
  project  = module.project_vpc_1.project_id

  name                  = "vpn-tunnel-gw1-int0"
  region                = "europe-west1"
  router                = google_compute_router.cr_vpc_1.self_link
  vpn_gateway           = google_compute_ha_vpn_gateway.gw_vpc_1.self_link
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gw_vpc_2.self_link
  shared_secret         = "W0jYlpRWM2Y1hfUy9NucPVAscLBnowFh"
  vpn_gateway_interface = 0
}

## Gateway 1, Tunnel 1
resource "google_compute_vpn_tunnel" "vpn_tunnel_gw1_int1" {
  provider = google-beta
  project  = module.project_vpc_1.project_id

  name                  = "vpn-tunnel-gw1-int1"
  region                = "europe-west1"
  router                = google_compute_router.cr_vpc_1.self_link
  vpn_gateway           = google_compute_ha_vpn_gateway.gw_vpc_1.self_link
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gw_vpc_2.self_link
  shared_secret         = "LYpL4ppRkb0kUGnWn8txxeZC1XQ0xCFD"
  vpn_gateway_interface = 1
}

## Gateway 2, Tunnel 0
resource "google_compute_vpn_tunnel" "vpn_tunnel_gw2_int0" {
  provider = google-beta
  project  = module.project_vpc_2.project_id

  name                  = "vpn-tunnel-gw2-int0"
  region                = "europe-west1"
  router                = google_compute_router.cr_vpc_2.self_link
  vpn_gateway           = google_compute_ha_vpn_gateway.gw_vpc_2.self_link
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gw_vpc_1.self_link
  shared_secret         = "W0jYlpRWM2Y1hfUy9NucPVAscLBnowFh"
  vpn_gateway_interface = 0
}

## Gateway 2, Tunnel 1
resource "google_compute_vpn_tunnel" "vpn_tunnel_gw2_int1" {
  provider = google-beta
  project  = module.project_vpc_2.project_id

  name                  = "vpn-tunnel-gw2-int1"
  region                = "europe-west1"
  router                = google_compute_router.cr_vpc_2.self_link
  vpn_gateway           = google_compute_ha_vpn_gateway.gw_vpc_2.self_link
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gw_vpc_1.self_link
  shared_secret         = "LYpL4ppRkb0kUGnWn8txxeZC1XQ0xCFD"
  vpn_gateway_interface = 1
}

# Interfaces and BGP Peer sessions
## Cloud Router 1, Interface 0
resource "google_compute_router_interface" "cr1_int0_to_gw2_int0" {
  provider = google-beta
  project  = module.project_vpc_1.project_id

  name       = "router1-interface0"
  router     = google_compute_router.cr_vpc_1.name
  region     = "europe-west1"
  ip_range   = "169.254.100.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_gw1_int0.self_link
}

resource "google_compute_router_peer" "cr1_int0_to_gw2_int0_peer" {
  provider = google-beta
  project  = module.project_vpc_1.project_id

  name                      = "router1-int0-peer"
  router                    = google_compute_router.cr_vpc_1.name
  interface                 = google_compute_router_interface.cr1_int0_to_gw2_int0.name
  region                    = "europe-west1"
  peer_ip_address           = "169.254.100.2"
  peer_asn                  = 65002
  advertised_route_priority = 100
}

## Cloud Router 2, Interface 0
resource "google_compute_router_interface" "cr2_int0_to_gw1_int0" {
  provider = google-beta
  project  = module.project_vpc_2.project_id

  name       = "router2-interface0"
  router     = google_compute_router.cr_vpc_2.name
  region     = "europe-west1"
  ip_range   = "169.254.100.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_gw2_int0.self_link
}

resource "google_compute_router_peer" "cr2_int0_to_gw1_int0_peer" {
  provider = google-beta
  project  = module.project_vpc_2.project_id

  name                      = "router2-int0-peer"
  region                    = "europe-west1"
  router                    = google_compute_router.cr_vpc_2.name
  interface                 = google_compute_router_interface.cr2_int0_to_gw1_int0.name
  peer_ip_address           = "169.254.100.1"
  peer_asn                  = 65001
  advertised_route_priority = 100
}

## Cloud Router 1, Interface 1
resource "google_compute_router_interface" "cr1_int1_to_gw2_int1" {
  provider = google-beta
  project  = module.project_vpc_1.project_id

  name       = "router1-interface1"
  router     = google_compute_router.cr_vpc_1.name
  region     = "europe-west1"
  ip_range   = "169.254.200.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_gw1_int1.self_link
}

resource "google_compute_router_peer" "cr1_int1_to_gw2_int1_peer" {
  provider = google-beta
  project  = module.project_vpc_1.project_id

  name                      = "router1-int1-peer"
  region                    = "europe-west1"
  router                    = google_compute_router.cr_vpc_1.name
  interface                 = google_compute_router_interface.cr1_int1_to_gw2_int1.name
  peer_ip_address           = "169.254.200.2"
  peer_asn                  = 65002
  advertised_route_priority = 100
}

## Cloud Router 2, Interface 1
resource "google_compute_router_interface" "cr2_int1_to_gw1_int1" {
  provider = google-beta
  project  = module.project_vpc_2.project_id

  name       = "router2-interface1"
  router     = google_compute_router.cr_vpc_2.name
  region     = "europe-west1"
  ip_range   = "169.254.200.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_gw2_int1.self_link
}

resource "google_compute_router_peer" "cr2_int1_to_gw1_int1_peer" {
  provider = google-beta
  project  = module.project_vpc_2.project_id

  name                      = "router2-int1-peer"
  region                    = "europe-west1"
  router                    = google_compute_router.cr_vpc_2.name
  interface                 = google_compute_router_interface.cr2_int1_to_gw1_int1.name
  peer_ip_address           = "169.254.200.1"
  peer_asn                  = 65001
  advertised_route_priority = 100
}