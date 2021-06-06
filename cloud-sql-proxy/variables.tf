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
variable "proxy_access_identities" {
  description = "List of identities who require access to the SQL proxy, and database.  Every identity should be prefixed with the type, for example user:, serviceAccount: and/or group:"
  type        = set(string)
  default     = []
}

variable "region" {
  description = "Default region to use for all resources.  Will be used to configure the provider."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Default zone to use for all resources.  Will be used to configure the provider."
  type        = string
  default     = "europe-west1-b"
}

variable "enable_internet_egress_traffic" {
  description = "The compute instance requires external access to download patches and scripts. Once the VM is installed, set this to false, so the Cloud NAT and Router are deleted."
  type        = bool
  default     = true
}

variable "enable_ssh_access" {
  description = "Allow SSH access to the VM.  This will enable SSH access for all identities, so be careful when enabling this."
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
  default     = "v1.23.0"
}

variable "create_custom_compute_get_role" {
  description = "Create a custom role that contains the bare minimum for retrieving Compute instance details.  The identity running this code requires the Project IAM Role permissions on the project, or the equivalent at organization level."
  type        = bool
  default     = true
}