locals {
  project_services = [
    "compute.googleapis.com"
  ]
}

resource "random_pet" "randomizer" {}

resource "google_project" "gcp_project" {
  folder_id       = var.parent_folder_id
  name            = var.gcp_project_name
  project_id      = "${var.gcp_project_name}-${random_pet.randomizer.id}"
  billing_account = var.billing_account_id
}

resource "google_project_service" "project_services" {
  for_each = toset(local.project_services)
  project  = google_project.gcp_project.project_id
  service  = each.value
}

resource "google_compute_network" "connectivity_vpc" {
  project                 = google_project.gcp_project.project_id
  name                    = "conn-network"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.project_services]
}

resource "google_compute_subnetwork" "connectivity_subnet" {
  project                  = google_project.gcp_project.project_id
  ip_cidr_range            = "10.100.0.0/16"
  name                     = "conn-sn"
  network                  = google_compute_network.connectivity_vpc.self_link
  private_ip_google_access = true
  region                   = "europe-west2"
  depends_on               = [google_project_service.project_services]
}

resource "google_service_account" "storage_access" {
  project      = google_project.gcp_project.project_id
  account_id   = "sa-tst-access"
  display_name = "Test Access"
  description  = "Service Account to test access to services across platforms."
}

resource "google_project_iam_member" "sa_access_roles" {
  project = google_project.gcp_project.project_id
  member  = "serviceAccount:${google_service_account.storage_access.email}"
  role    = "roles/owner"
}

resource "google_storage_bucket" "test_bucket" {
  project  = google_project.gcp_project.project_id
  name     = "sc-conn-tst-bckt"
  location = "EU"
}

// VPN
resource "google_compute_ha_vpn_gateway" "gcp_vpn_gateway" {
  provider    = google-beta
  project     = google_project.gcp_project.project_id
  network     = google_compute_network.connectivity_vpc.self_link
  name        = "gcp-gw"
  description = "VPN Gateway for AWS."
  region      = "europe-west1"
}

resource "google_compute_external_vpn_gateway" "aws_vpn_gateway" {
  provider        = google-beta
  project         = google_project.gcp_project.project_id
  name            = "aws-gateway"
  description     = "VPN gateway on AWS side"
  redundancy_type = "FOUR_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.vpn_conn_one.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.vpn_conn_one.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.vpn_conn_two.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.vpn_conn_two.tunnel2_address
  }
}

resource "google_compute_router" "gcp_cr_gw" {
  project     = google_project.gcp_project.project_id
  network     = google_compute_network.connectivity_vpc.self_link
  name        = "gcp-aws-cr"
  region      = "europe-west1"
  description = "Cloud Router for VPN connectivity between GCP and AWS."

  bgp {
    asn = 65000
  }
}

resource "google_compute_vpn_tunnel" "tunnel_one" {
  provider                        = google-beta
  project                         = google_project.gcp_project.project_id
  name                            = "vpn-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_vpn_gateway.self_link
  shared_secret                   = aws_vpn_connection.vpn_conn_one.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_vpn_gateway.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.gcp_cr_gw.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
  region                          = "europe-west1"
}

resource "google_compute_vpn_tunnel" "tunnel_two" {
  provider                        = google-beta
  project                         = google_project.gcp_project.project_id
  name                            = "vpn-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_vpn_gateway.self_link
  shared_secret                   = aws_vpn_connection.vpn_conn_one.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_vpn_gateway.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.gcp_cr_gw.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
  region                          = "europe-west1"
}

resource "google_compute_vpn_tunnel" "tunnel_three" {
  provider                        = google-beta
  project                         = google_project.gcp_project.project_id
  name                            = "vpn-tunnel-3"
  region                          = "europe-west1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_vpn_gateway.self_link
  shared_secret                   = aws_vpn_connection.vpn_conn_two.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_vpn_gateway.self_link
  peer_external_gateway_interface = 2
  router                          = google_compute_router.gcp_cr_gw.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel_four" {
  provider                        = google-beta
  project                         = google_project.gcp_project.project_id
  name                            = "vpn-tunnel-4"
  region                          = "europe-west1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_vpn_gateway.self_link
  shared_secret                   = aws_vpn_connection.vpn_conn_two.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_vpn_gateway.self_link
  peer_external_gateway_interface = 3
  router                          = google_compute_router.gcp_cr_gw.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "router_1_int_0" {
  project    = google_project.gcp_project.project_id
  router     = google_compute_router.gcp_cr_gw.name
  name       = "interface-1"
  ip_range   = "${aws_vpn_connection.vpn_conn_one.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_one.name
  region     = "europe-west1"
}

resource "google_compute_router_interface" "router_1_int_1" {
  project    = google_project.gcp_project.project_id
  router     = google_compute_router.gcp_cr_gw.name
  name       = "interface-2"
  ip_range   = "${aws_vpn_connection.vpn_conn_one.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_two.name
  region     = "europe-west1"
}

resource "google_compute_router_peer" "router_1_peer_0" {
  project                   = google_project.gcp_project.project_id
  name                      = "bgp-peer-10"
  router                    = google_compute_router.gcp_cr_gw.name
  peer_ip_address           = aws_vpn_connection.vpn_conn_one.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.vpn_conn_one.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_1_int_0.name
  region                    = "europe-west1"
}

resource "google_compute_router_peer" "router_1_peer_1" {
  project                   = google_project.gcp_project.project_id
  name                      = "bgp-peer-11"
  router                    = google_compute_router.gcp_cr_gw.name
  peer_ip_address           = aws_vpn_connection.vpn_conn_one.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.vpn_conn_one.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_1_int_1.name
  region                    = "europe-west1"
}
