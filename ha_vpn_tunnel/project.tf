/**
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
module "project_vpc_1" {
  source = "git@github.com:debakkerb/tf-modules//10_-_standalone/project"

  billing_account_id = local.billing_account_id
  folder_id          = local.sandbox_folder_id

  project_name = "bdb-vpn-vpc-1"

  project_services = [
    "compute.googleapis.com"
  ]
}

module "project_vpc_2" {
  source = "git@github.com:debakkerb/tf-modules//10_-_standalone/project"

  billing_account_id = local.billing_account_id
  folder_id          = local.sandbox_folder_id

  project_name = "bdb-vpn-vpc-2"

  project_services = [
    "compute.googleapis.com"
  ]
}