locals {
  sandbox_orchestration_project_id   = data.terraform_remote_state.shared_service_backend.outputs.sandbox_project_id
  sandbox_orchestration_project_nmbr = data.terraform_remote_state.shared_service_backend.outputs.sandbox_project_nmbr
  organization_id                    = data.terraform_remote_state.shared_service_backend.outputs.organization_id
  billing_account_id                 = data.terraform_remote_state.shared_service_backend.outputs.billing_account
  sandbox_folder_id                  = data.terraform_remote_state.shared_service_backend.outputs.sandbox_folder_id

}

module "host_project" {
  source = "git@github.com:debakkerb/tf-modules//10_-_standalone/project"

  billing_account_id = local.billing_account_id
  project_name       = "bdb-mon-host"

  folder_id = local.sandbox_folder_id
}

module "service_project" {
  source = "git@github.com:debakkerb/tf-modules//10_-_standalone/project"

  billing_account_id = local.billing_account_id
  project_name       = "bdb-mon-svc"

  folder_id = local.sandbox_folder_id
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = module.host_project.project_id
  depends_on = [
    module.host_project.project_id
  ]
}

resource "google_compute_shared_vpc_service_project" "mon_service" {
  host_project    = module.host_project.project_id
  service_project = module.service_project.project_id

  depends_on = [
    google_compute_shared_vpc_host_project.host,
    module.service_project
  ]
}

resource "google_compute_network" "host_network" {
  project = module.host_project.project_id

  name = "host-network"
  depends_on = [
    google_compute_shared_vpc_service_project.mon_service
  ]
}

resource "google_compute_subnetwork" "host_subnetwork" {
  project = module.host_project.project_id

  ip_cidr_range = "10.0.0.0/16"
  name          = "eu-west1-sn"
  network       = google_compute_network.host_network.self_link
  region        = "europe-west1"
}

data "google_compute_image" "debian" {
  family  = "debian-9"
  project = "debian-cloud"
}

data "template_file" "startup_script" {
  template = file("./startup/startup_script")
}

resource "google_compute_instance" "http_server" {
  project = module.service_project.project_id

  name                      = "http-server-vm1"
  machine_type              = "n1-standard-1"
  zone                      = "europe-west1-b"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network = google_compute_network.host_network.self_link
  }

  service_account {
    email  = google_service_account.compute_service_account.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = data.template_file.startup_script.rendered

  tags = ["http"]

  depends_on = [
    module.service_project
  ]
}

resource "google_compute_firewall" "allow_ping" {
  project = module.host_project.project_id

  name    = "allow-icmp"
  network = google_compute_network.host_network.self_link

  source_ranges = ["10.200.0.0/28"]

  target_tags = [
    "http"
  ]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  enable_logging = true

}

resource "google_service_account" "compute_service_account" {
  project = module.service_project.project_id

  account_id   = "http-host-vm"
  display_name = "HTTP Host VM"
}

module "function_host" {
  source = "git@github.com:debakkerb/tf-modules//10_-_standalone/project"

  billing_account_id = local.billing_account_id
  project_name       = "fnc-status-project"
  folder_id          = local.sandbox_folder_id

  project_services = [
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "appengine.googleapis.com",
    "vpcaccess.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

resource "google_project_iam_member" "network_mgmt_test" {
  project = module.function_host.project_id

  member = "user:bjorn@bdb-tst.co.uk"
  role   = "roles/networkmanagement.admin"
}

resource "google_compute_network" "private_function_network" {
  project = module.function_host.project_id

  name                    = "function-nw"
  auto_create_subnetworks = false
  depends_on = [
    module.function_host
  ]

}

resource "google_compute_subnetwork" "private_function_subnet" {
  project = module.function_host.project_id

  network       = google_compute_network.private_function_network.self_link
  ip_cidr_range = "10.100.0.0/16"
  name          = "function-snw"
  region        = "europe-west1"
}

resource "google_storage_bucket" "cloud_function_source_bucket" {
  project = module.function_host.project_id

  name = "bdb-cfn-healthcheck"
  versioning {
    enabled = true
  }
}

data "archive_file" "healthcheck_zip" {
  output_path = "${path.root}/healthcheck.zip"
  source_dir  = "${path.root}/healthcheck/"
  type        = "zip"
}

resource "google_storage_bucket_object" "healthcheck_upload" {
  name   = "healthcheck.zip"
  bucket = google_storage_bucket.cloud_function_source_bucket.name
  source = "${path.root}/healthcheck.zip"

  depends_on = [
    data.archive_file.healthcheck_zip
  ]
}

resource "google_pubsub_topic" "healthcheck_topic" {
  project = module.function_host.project_id
  name    = "vm-healthcheck-topic"
}

resource "google_cloudfunctions_function" "healthcheck_function" {
  project = module.function_host.project_id

  name                = "helloPubSub"
  description         = "Cloud Function to send a healthcheck to a VM, running in a Shared VPC."
  available_memory_mb = 128
  timeout             = 60

  source_archive_bucket = google_storage_bucket.cloud_function_source_bucket.name
  source_archive_object = google_storage_bucket_object.healthcheck_upload.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${module.function_host.project_id}/topics/${google_pubsub_topic.healthcheck_topic.name}"
  }

  environment_variables = {
    TARGET_IP = google_compute_instance.http_server.network_interface[0].network_ip
  }

  vpc_connector = "projects/${module.function_host.project_id}/locations/europe-west1/connectors/${google_vpc_access_connector.connector.name}"

  region = "europe-west1"

  runtime = "nodejs10"
}

resource "google_cloud_scheduler_job" "scheduled_job" {
  project = module.function_host.project_id

  name        = "healthcheck-scheduler-job"
  description = "Checking the health of the VM."
  schedule    = "5 * * * *"

  region = "europe-west1"

  pubsub_target {
    topic_name = google_pubsub_topic.healthcheck_topic.id
    data       = base64encode("test")
  }

  depends_on = [
    google_app_engine_application.trigger_app
  ]
}

resource "google_app_engine_application" "trigger_app" {
  project = module.function_host.project_id

  location_id = "europe-west"

  depends_on = [
    module.function_host.services
  ]
}

resource "google_vpc_access_connector" "connector" {
  project = module.function_host.project_id

  name          = "vpcconn"
  region        = "europe-west1"
  ip_cidr_range = "10.200.0.0/28"
  network       = google_compute_network.private_function_network.name

  depends_on = [
    google_app_engine_application.trigger_app
  ]
}

resource "google_compute_network_peering" "network_shared_vpc_function" {
  name         = "peer-shar-fnc"
  network      = google_compute_network.host_network.self_link
  peer_network = google_compute_network.private_function_network.self_link
}

resource "google_compute_network_peering" "function_shared_vpc" {
  name         = "peer-fnc-shar"
  network      = google_compute_network.private_function_network.self_link
  peer_network = google_compute_network.host_network.self_link
}

resource "google_project_iam_member" "cloud_fnc_service_account" {
  project = module.function_host.project_id

  member = "serviceAccount:service-${module.function_host.project_number}@gcf-admin-robot.iam.gserviceaccount.com"
  role   = "roles/compute.networkUser"
}