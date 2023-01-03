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

resource "google_compute_global_address" "sql_instance_private_ip" {
  provider = google-beta

  project       = module.host_project.project_id
  name          = "sql-private-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.host_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.host_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_instance_private_ip.name]

  depends_on = [
    module.service_project.enabled_apis
  ]
}

resource "random_id" "name_randomizer" {
  byte_length = 4
  keepers = {
    regenerate_sql_server = var.regenerate_sql_server
  }
}

resource "google_sql_database_instance" "private_sql_instance" {
  provider = google-beta

  project             = module.service_project.project_id
  deletion_protection = false
  name                = "${var.prefix}-sql-instance-${random_id.name_randomizer.hex}"
  region              = var.region
  database_version    = "POSTGRES_11"

  settings {
    tier              = "db-f1-micro"
    disk_size         = 10
    disk_type         = "PD_SSD"
    availability_type = "REGIONAL"

    backup_configuration {
      binary_log_enabled = false
      enabled            = true
    }

    ip_configuration {
      private_network = google_compute_network.host_network.id
      require_ssl     = false
      ipv4_enabled    = false
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "google_sql_database" "records_db" {
  project  = module.service_project.project_id
  instance = google_sql_database_instance.private_sql_instance.name
  name     = "records"
}

resource "google_sql_user" "user_dev_access" {
  project  = module.service_project.project_id
  instance = google_sql_database_instance.private_sql_instance.name
  name     = "db-user"
  password = random_password.db_user_password.result
}

resource "random_password" "db_user_password" {
  length      = 15
  min_lower   = 3
  min_numeric = 3
  min_special = 5
  min_upper   = 3
}

resource "google_secret_manager_secret" "sql_db_user_password" {
  project   = module.service_project.project_id
  secret_id = "sql-db-password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "sql_db_user_password" {
  secret      = google_secret_manager_secret.sql_db_user_password.id
  secret_data = random_password.db_user_password.result
}