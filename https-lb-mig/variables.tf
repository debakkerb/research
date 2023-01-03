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

variable "organization_id" {}
variable "billing_account_id" {}
variable "folder_id" {}

variable "prefix" {
  description = "Prefix which will be used as the start for each resource name."
  type        = string
}

variable "cidr_range" {
  description = "IP CIDR range for the subnet that will host the managed instance group."
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "Region where all the resources should be hosted."
  type        = string
  default     = "europe-west1"
}

variable "domain" {
  description = "Domain that will be used to generate the SSL certificate"
  type        = string
}

variable "enable_egress_traffic" {
  description = "Enable traffic to the public internet from the VMs."
  type        = bool
  default     = true
}

variable "enable_iap_access" {
  description = "Enable SSH access to the underlying VMs."
  type        = bool
  default     = false
}
