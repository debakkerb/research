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

variable "acm_cluster_identity_name" {
  description = "Identity name of the service account attached to the GKE cluster"
  type        = string
  default     = "acm-cluster-id"
}

variable "acm_cluster_master_cidr_block" {
  description = "CIDR block that can be used for the GKE control plane "
  type        = string
  default     = "10.255.0.0/28"
}

variable "acm_cluster_name" {
  description = "Name of the ACM cluster"
  type        = string
  default     = "acm-main-cluster"
}

variable "acm_cluster_location" {
  description = "Location where the Anthos Config Mgmt cluster will be created.  Can either be a region (regional cluster) or a zone (zonal cluster).  Make sure it corresponds to the Region variable, as that is where the subnet will be created."
  type        = string
  default     = "europe-west1"
}

variable "billing_account_id" {
  description = "Billing account to attach to the project"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "Folder ID that should be the parent of the project."
  type        = string
}

variable "network_name" {
  description = "Name of the network where the ACM cluster will be created."
  type        = string
  default     = "acm-cc-nw"
}

variable "organization_id" {
  description = "Organization ID where the project should be created."
  type        = string
}

variable "project_name" {
  description = "Name of the project.  A unique identifier will be appended to the project ID automatically."
  type        = string
  default     = "rsrch-acm-tst"
}

variable "region" {
  description = "Default region for all resources inside this project."
  type        = string
  default     = "europe-west1"
}

variable "subnet_cidr_range" {
  description = "Primary IP range of the subnet where the ACM cluster will run"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnetwork_name" {
  description = "Name of the subnetwork where the ACM cluster will run."
  type        = string
  default     = "europe-west1"
}

