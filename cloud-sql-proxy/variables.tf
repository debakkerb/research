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
variable "parent_folder_id" {}
variable "prefix" {}
variable "identity" {}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "enable_internet_egress_traffic" {
  description = "The compute instance requires external access to download patches and scripts. Once the VM is installed, set this to false, so the Cloud NAT and Router are deleted."
  type        = bool
  default     = false
}

variable "enable_ssh_access" {
  description = "Block SSH access to the VM.  Enabled by default."
  type        = bool
  default     = false
}

variable "subnet_cidr_range" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "cloud_sql_proxy_version" {
  description = "Which version to use of the Cloud SQL proxy."
  type        = string
  default     = "v1.21.0"
}

variable "create_custom_compute_get_role" {
  description = "Create a custom role that contains the bare minimum for retrieving Compute instance details.  The identity running this code requires the Project IAM Role permissions on the project, or the equivalent at organization level."
  type        = bool
  default     = true
}