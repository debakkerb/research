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
resource "local_file" "create_organization_file" {
  filename = "${path.module}/create_organization.sh"
  content = templatefile("${path.module}/templates/create_organization.sh.tmpl", {
    PROJECT_ID   = module.default.project_id
    REGION       = var.region
    NETWORK_NAME = google_compute_network.default.name
  })
  file_permission = "0777"
}

resource "null_resource" "create_organization" {
  triggers = {
    create_organization_sha = sha1(file("${path.module}/create_organization.sh"))
  }

  working_dir = path.module
  command     = "./create_organization.sh"
}

resource "template_file" "apigee_get_host_template" {
  template = "${path.module}/templates/apigee_endpoint_retrieval.sh.tmpl"
  vars = {
    PROJECT_ID = module.default.project_id
  }
}

data "external" "apigee_get_host_command" {
  program = ["bash", "${path.module}/apigee_endpoint_retrieval.sh"]

  depends_on = [
    template_file.apigee_get_host_template,
    null_resource.create_organization,
    local_file.create_organization_file
  ]
}

data "google_compute_image" "debian" {
  project = "debian-cloud"
  family  = "debian-10"
}

data "google_compute_zones" "zones" {
  project = module.default.project_id
  region  = var.region
}

resource "google_compute_instance_template" "apigee_instance_group_template" {
  project      = module.default.project_id
  region       = var.region
  machine_type = "e2-medium"
  tags         = ["http-server", "apigee-mig-proxy", "gke-apigee-proxy"]

  disk {
    boot         = true
    disk_size_gb = 20
    source_image = data.google_compute_image.debian.self_link
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.self_link
  }

  metadata = {
    ENDPOINT           = data.external.apigee_get_host_command.result.host,
    startup-script-url = "gs://apigee-5g-saas/apigee-envoy-proxy-release/latest/conf/startup-script.sh"
  }
}

resource "google_compute_instance_group" "apigee_instance_group" {
  project = module.default.project_id
  name    = "${var.prefix}-apigee-mig"
  zone    = data.google_compute_zones.zones.names[0]

}