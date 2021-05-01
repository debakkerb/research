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

variable "block_egress" {
  description = "The compute instance requires external access to download patches and scripts. Once the VM is installed, set this to false, so the Cloud NAT and Router are deleted."
  default     = false
  type        = bool
}

variable "subnet_cidr_range" {
  description = "CIDR block for the subnet"
  default     = "10.0.0.0/24"
}

variable "cloud_sql_proxy_version" {
  type    = string
  default = "v1.21.0"
}