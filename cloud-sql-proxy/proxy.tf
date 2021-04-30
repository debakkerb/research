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

data "google_compute_image" "debian" {
  project = "debian-cloud"
  family  = "debian-10"
}

resource "google_compute_instance" "proxy_instance" {
  project                   = module.cloud_sql_proxy_service_project.project_id
  machine_type              = "n1-standard-1"
  name                      = "sql-proxy"
  zone                      = var.zone
  allow_stopping_for_update = true
  description               = "Cloud SQL proxy"
  deletion_protection       = false

  metadata = {
    startup-script = local_file.sql_proxy_install_script.content
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.sql_subnetwork.self_link
  }

  service_account {
    email  = google_service_account.sql_proxy_service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["sql-proxy"]

  depends_on = [
    google_compute_shared_vpc_host_project.host_project,
    google_compute_shared_vpc_service_project.service_project,
    null_resource.chmod_execute_sql_install_script
  ]
}

resource "google_compute_project_metadata_item" "oslogin" {
  project = module.cloud_sql_proxy_service_project.project_id
  key     = "oslogin-enabled"
  value   = "TRUE"
}

data "template_file" "sql_proxy_install_script_tmpl" {
  template = file("${path.module}/scripts/cloud_sql_proxy_install.sh.tpl")
  vars = {
    instance_connection_name = google_sql_database_instance.private_sql_instance.connection_name
    cloud_sql_proxy_version  = var.cloud_sql_proxy_version
  }
}

resource "local_file" "sql_proxy_install_script" {
  content  = data.template_file.sql_proxy_install_script_tmpl.rendered
  filename = "${path.module}/scripts/cloud_sql_proxy_install.sh"
}

resource "null_resource" "chmod_execute_sql_install_script" {
  provisioner "local-exec" {
    command = "chmod +x ${local_file.sql_proxy_install_script.filename}"
  }
}
