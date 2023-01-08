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

variable "folder_id" {
  description = "Folder ID where the project will be created."
  type        = string
}

variable "organization_id" {
  description = "Organization ID where the project will be created"
  type        = string
}

variable "parent" {
  description = "Parent where the firewall policy should be applied"
  type        = string
}

variable "policy_short_name" {
  description = "Short name for the firewall policy."
  type        = string
  default     = "rsrch-tst-policy"
}

variable "project_name" {
  description = "Project name where we are going to define the hierarchical policy"
  type        = string
}

