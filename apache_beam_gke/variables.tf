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
variable "prefix" {}

variable "project_name" {
  description = "Name for the project."
  type        = string
  default     = "beam-gke"
}

variable "network_name" {
  description = "Name for the network."
  type        = string
  default     = "nw"
}

variable "subnet_name" {
  description = "Name for the subnetwork."
  type        = string
  default     = "snw"
}

variable "cidr_block" {
  description = "CIDR block for the network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_range_name" {
  description = "Name for the secondary IP range, used by Pods."
  type        = string
  default     = "pod-ip-range"
}

variable "pod_range_cidr" {
  description = "CIDR range for the Pods."
  type        = string
  default     = "10.100.0.0/16"
}

variable "svc_range_name" {
  description = "Name for the secondary IP range, used by Services."
  type        = string
  default     = "svc-ip-range"
}

variable "svc_range_cidr" {
  description = "CIDR range for the services."
  type        = string
  default     = "10.150.0.0/16"
}

variable "region" {
  description = "Default region where all resources will be created."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Default zone where all ZONAL resources will be created."
  type        = string
  default     = "europe-west1-b"
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "cluster"
}

variable "channel" {
  description = "Default channel for the cluster."
  type        = string
  default     = "STABLE"
}

variable "master_ipv4_cidr_block" {
  description = "IPV4 block for the GKE master."
  type        = string
  default     = "10.255.0.0/28"
}

variable "cluster_version" {
  description = "Default version of the cluster."
  type        = string
  default     = "1.20.10-gke.1600"
}