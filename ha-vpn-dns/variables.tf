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

variable "subnet_one_name" {
  description = "Name of the first subnet"
  type        = string
  default     = "ha-vpn-snw-one"
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

