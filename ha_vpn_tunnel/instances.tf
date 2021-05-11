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

module "instance_network_a" {
  source = "./modules/instance"

  prefix          = var.prefix
  suffix          = "a"
  project_id      = module.shared_vpc_a.service_project_id
  subnet_selflink = module.shared_vpc_a.subnet_one_selflink
}

module "instance_network_b" {
  source = "./modules/instance"

  prefix          = var.prefix
  suffix          = "b"
  project_id      = module.shared_vpc_b.service_project_id
  subnet_selflink = module.shared_vpc_b.subnet_one_selflink
}