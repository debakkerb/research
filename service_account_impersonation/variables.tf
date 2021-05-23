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

variable "region" {
  description = "Region to assign to resources.  Used as part of the provider configuration."
  type        = string
}

variable "zone" {
  description = "Zone to assign to resources.  Used as part of the provider configuration."
  type        = string
}

variable "prefix" {
  description = "Prefix to assign to resource names and IDs.  Defaults to tst."
  type        = string
  default     = "tst"
}

variable "organization_id" {
  description = "Organization ID where to create resources.  Used for project creation."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account to assign to projects."
  type        = string
}