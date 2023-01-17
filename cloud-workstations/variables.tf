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
  description = "Billing Account ID where the project will be created."
  type        = string
}

variable "cidr_range" {
  description = "CIDR range for the subnet."
  type        = string
  default     = "10.0.0.0/16"
}

variable "folder_id" {
  description = "Folder ID which will be the parent of the folder"
  type        = string
}

variable "network_name" {
  description = "Name of the network where workstations will be created."
  type        = string
  default     = "ws-test-network"
}

variable "organization_id" {
  description = "Organization where the project should be created."
  type        = string
}

variable "project_name" {
  description = "Name of the project, will be suffixed with a unique identifier."
  type        = string
  default     = "rsrch-ws-test"
}

variable "region" {
  description = "Default region for all resources."
  type        = string
  default     = "europe-west1"
}

variable "subnet_name" {
  description = "Name of the subnetwork where the workstations will be hosted"
  type        = string
  default     = "ws-test-subnet"
}
