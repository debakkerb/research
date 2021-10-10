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

variable "prefix" {
  description = "Prefix which will be added to all resources."
  type        = string
}

variable "organization_id" {
  description = "Organization ID where the project and resources will be created."
  type        = string
}

variable "billing_account_id" {
  description = "Billing Account ID that should be linked to the project."
  type        = string
}

variable "folder_id" {
  description = "Folder ID of the folder where the project should be created."
  type        = string
}

variable "region" {
  description = "Region where the resources will be created."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone where the resources will be created."
  type        = string
  default     = "europe-west1-b"
}

variable "cidr_block" {
  description = "CIDR block for the subnet that will host the cluster and K8s resources."
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr_range" {
  description = "CIDR block for the Pods."
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_cidr_range" {
  description = "CIDR block for the Services."
  type        = string
  default     = "10.2.0.0/16"
}