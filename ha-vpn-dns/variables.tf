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

variable "billing_account_id" {
  description = "Billing account to attach to the project"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "Folder ID that should be the parent of the project."
  type        = string
}

variable "organization_id" {
  description = "Organization ID where the project should be created."
  type        = string
}

variable "project_name" {
  description = "Name of the project.  A unique identifier will be appended to the project ID automatically."
  type        = string
  default     = "rsrch-ha-vpn-tst"
}

variable "network_one_name" {
  description = "Name of the first network."
  type        = string
  default     = "ha-vpn-nw-one"
}

variable "network_two_name" {
  description = "Name of the second network."
  type        = string
  default     = "ha-vpn-nw-two"
}

variable "network_two_router_name" {
  description = "Name of the network router, attached to the second network."
  type        = string
  default     = "ha-vpn-rtr-two"
}

variable "subnet_one_name" {
  description = "Name of the first subnet"
  type        = string
  default     = "ha-vpn-snw-one"
}

variable "network_one_router_name" {
  description = "Name of the network router, attached to the first network."
  type        = string
  default     = "ha-vpn-rtr-one"
}

variable "router_one_interface_one_peer_ip_address" {
  description = "IP address of the BGP exchange"
  type        = string
  default     = "169.254.0.2"
}

variable "router_one_interface_zero_peer_name" {
  description = "Name of the BGP session, peering between router 1 and 2, running over the first VPN tunnel."
  type        = string
  default     = "ha-vpn-peer-one-two-0"
}

variable "router_one_interface_two_peer_ip_address" {
  description = "IP address of the BGP exchange"
  type        = string
  default     = "169.254.1.1"
}

variable "router_one_interface_one_peer_name" {
  description = "Name of the BGP session, peering between router 1 and 2, running over the second VPN tunnel."
  type        = string
  default     = "ha-vpn-peer-one-two-1"
}


variable "subnet_one_cidr_range" {
  description = "CIDR range for the first subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "subnet_one_region" {
  description = "Region for the first subnet"
  type        = string
  default     = "europe-west1"
}

variable "subnet_two_name" {
  description = "Name of the first subnet"
  type        = string
  default     = "ha-vpn-snw-two"
}

variable "subnet_two_cidr_range" {
  description = "CIDR range for the first subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "subnet_two_region" {
  description = "Region for the first subnet"
  type        = string
  default     = "europe-west2"
}

variable "trusted_users" {
  description = "List of users who should be able to access the VMs, incl. their user type (user:, serviceAccount: and group: )."
  type        = set(string)
}

variable "tunnel_four_interface_ip_range" {
  description = "IP range for the interface, attached to tunnel 4."
  type        = string
  default     = "169.254.1.1/30"
}

variable "tunnel_four_interface_name" {
  description = "Name for the interface, VPN Gateway 2 to VPN Gateway 1, interface 1."
  type        = string
  default     = "vpn-tunnel-four-interface"
}

variable "tunnel_one_interface_name" {
  description = "Name for the interface, VPN Gateway 1 to VPN Gateway 2, interface 0."
  type        = string
  default     = "vpn-tunnel-one-interface"
}

variable "tunnel_one_interface_ip_range" {
  description = "IP range for the interface, attached to tunnel 1."
  type        = string
  default     = "169.254.0.1/30"
}

variable "tunnel_three_interface_ip_range" {
  description = "IP range for the interface, attached to tunnel 3"
  type        = string
  default     = "169.254.0.2/30"
}

variable "tunnel_three_interface_name" {
  description = "Name for the interface, Gateway 2 to VPN Gateway 1, interface 1."
  type        = string
  default     = "vpn-tunnel-three-interface"
}

variable "tunnel_two_interface_ip_range" {
  description = "IP range for the interface, attached to tunnel 2."
  type        = string
  default     = "169.254.1.2/30"
}

variable "tunnel_two_interface_name" {
  description = "NAme for the interface, VPN Gateway 1 to VPN Gateway 2, interface 1."
  type        = string
  default     = "vpn-tunnel-two-interface"
}

variable "vm_one_identity_name" {
  description = "Name of the first service account, attached to the first VM."
  type        = string
  default     = "vm-one-identity"
}

variable "vm_two_identity_name" {
  description = "Name of the second service account, attached to the second VM."
  type        = string
  default     = "vm-two-identity"
}

variable "vm_image_family" {
  description = "Image family that will be used to create both VMs."
  type        = string
  default     = "debian-11"
}

variable "vm_image_project" {
  description = "Image project that contains the VM image to be used."
  type        = string
  default     = "debian-cloud"
}

variable "vm_one_name" {
  description = "Name for the first VM"
  type        = string
  default     = "vm-one"
}

variable "vm_one_machine_type" {
  description = "Machine type for the first VM."
  type        = string
  default     = "e2-medium"
}

variable "vm_one_tags" {
  description = "Tags to be applied to the first VM"
  type        = list(string)
  default     = []
}

variable "vm_one_zone" {
  description = "Zone where the first VM will be created."
  type        = string
  default     = "europe-west1-b"
}

variable "vm_two_name" {
  description = "Name of the first VM"
  type        = string
  default     = "vm-two"
}

variable "vm_two_machine_type" {
  description = "Machine type for the second VM"
  type        = string
  default     = "e2-medium"
}

variable "vm_two_zone" {
  description = "Zone for the second VM."
  type        = string
  default     = "europe-west2-a"
}

variable "vm_two_tags" {
  description = "Tags to be applied to VM two."
  type        = list(string)
  default     = []
}

variable "vpn_gateway_one_name" {
  description = "Name of the VPN Gateway attached to network one"
  type        = string
  default     = "vpn-gateway-one"
}

variable "vpn_gateway_two_name" {
  description = "Name of the VPN Gateway attached to network two"
  type        = string
  default     = "vpn-gateway-two"
}

variable "vpn_gateway_region" {
  description = "Region where both VPN Gateways will reside."
  type        = string
  default     = "europe-west1"
}

variable "vpn_tunnel_four_name" {
  description = "Name for the fourth VPN tunnel, going from VPN Gateway 2 to VPN Gateway 1, on interface 0"
  type        = string
  default     = "vpn-tunnel-four"
}

variable "vpn_tunnel_one_name" {
  description = "Name for the first VPN tunnel, going from VPN Gateway 1 to VPN Gateway 2, on interface 0."
  type        = string
  default     = "vpn-tunnel-one"
}

variable "vpn_tunnel_three_name" {
  description = "Name for the third VPN tunnel, going from VPN Gateway 2 to VPN Gateway 1, on interface 0."
  type        = string
  default     = "vpn-tunnel-three"
}

variable "vpn_tunnel_two_name" {
  description = "Name for the second tunnel, going from VPN Gateway 1 to VPN Gateway 2, on interface 1"
  type        = string
  default     = "vpn-tunnel-two"
}

variable "router_two_interface_zero_peer_name" {
  description = "BGP peering, router 2 to router 1, interface 0"
  type        = string
  default     = "ha-vpn-peer-two-one-0"
}

variable "router_two_interface_zero_peer_ip_address" {
  description = "IP address for the peering session"
  type        = string
  default     = "169.254.0.1"
}

variable "router_two_interface_one_peer_name" {
  description = "BGP peering, router 2 to router 1, interface 1"
  type        = string
  default     = "ha-vpn-peer-two-one-1"
}

variable "router_two_interface_one_peer_ip_address" {
  description = "IP address for the peering session"
  type        = string
  default     = "169.254.1.2"
}
