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

variable "prefix" {
  description = "Prefix to be added to all resource names."
  type        = string
  default     = "rsrch"
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

variable "subnet_cidr_block" {
  description = "CIDR block allocated for the subnet hosting the resources."
  type        = string
  default     = "10.0.0.0/16"
}

variable "serverless_connector_subnet_cidr_block" {
  description = "CIDR block to be used for the serverless connector."
  type        = string
  default     = "10.255.0.0/28"
}