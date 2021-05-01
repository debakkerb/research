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

module "shared_vpc_a" {
  source = "./modules/shared_vpc"

  billing_account_id = var.billing_account_id
  organization_id    = var.organization_id
  parent_folder_id   = var.parent_folder_id

  prefix            = "rsrch"
  suffix            = "a"
  subnet_cidr_block = "10.0.0.0/16"
}

module "shared_vpc_b" {
  source = "./modules/shared_vpc"

  billing_account_id = var.billing_account_id
  organization_id    = var.organization_id
  parent_folder_id   = var.parent_folder_id

  prefix            = "rsrch"
  suffix            = "b"
  subnet_cidr_block = "10.1.0.0/16"
}
