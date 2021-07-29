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

variable "domain" {
  description = "Domain that will be used to access the APIs.  This will be used to create a managed SSL certificate."
  type        = string
}

variable "region" {
  description = "Region where the resources will be created."
  type        = string
  default     = "europe-west1"
}

variable "cidr_block" {
  description = "CIDR block to be used for the subnet that will be hosting the Apigee resources."
  type        = string
  default     = "10.0.0.0/16"
}
