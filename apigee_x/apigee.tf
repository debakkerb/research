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

resource "local_file" "destroy_organization_file" {
  filename = "${path.module}/destroy_organization.sh"
  content = templatefile("${path.module}/templates/destroy_organization.sh.tmpl", {
    PROJECT_ID = module.default.project_id
  })
  file_permission = "0777"
}

resource "null_resource" "create_organization" {
  triggers = {
    create_organization_sha = sha1(file("${path.module}/${local_file.create_organization_file.filename}"))
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "./create_organization.sh"
  }

  provisioner "local-exec" {
    when        = destroy
    working_dir = path.module
    command     = "./destroy_organization.sh"
  }

  depends_on = [
    local_file.create_organization_file,
    local_file.destroy_organization_file
  ]
}

resource "local_file" "apigee_get_host_template" {
  filename = "${path.module}/apigee_endpoint_retrieval.sh"
  content = templatefile("${path.module}/templates/apigee_endpoint_retrieval.sh.tmpl", {
    PROJECT_ID = module.default.project_id
  })
  file_permission = "0777"
}

data "external" "apigee_get_host_command" {
  program = ["bash", "${path.module}/apigee_endpoint_retrieval.sh"]

  depends_on = [
    null_resource.create_organization,
    local_file.create_organization_file,
    local_file.apigee_get_host_template
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

resource "google_service_account" "instance_service_account" {
  project      = module.default.project_id
  account_id   = "${var.prefix}-apigee-x-instance-id"
  display_name = "Apigee X Instance Identity"
  description  = "Identity to be attached to Apigee X instances."
}

resource "google_project_iam_member" "instance_iam_permissions" {
  project = module.default.project_id
  member  = "serviceAccount:${google_service_account.instance_service_account.email}"
  role    = "roles/storage.admin"
}

resource "google_compute_instance_template" "apigee_instance_group_template" {
  project      = module.default.project_id
  description  = "Instance template for Apigee instances to route traffic."
  region       = var.region
  machine_type = "e2-medium"
  tags         = ["https-server", "apigee-mig-proxy", "gke-apigee-proxy"]
  name         = "${var.prefix}-apigee-x"

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

  service_account {
    email  = google_service_account.instance_service_account.email
    scopes = ["cloud-platform"]
  }

}

resource "google_compute_region_instance_group_manager" "default" {
  project            = module.default.project_id
  name               = "${var.prefix}-mig-manager"
  base_instance_name = "${var.prefix}-apigee-x"
  description        = "Instance group manager for the Apigee X routing VMs."
  wait_for_instances = true
  region             = var.region
  target_size        = 2

  named_port {
    name = "https"
    port = 443
  }

  version {
    instance_template = google_compute_instance_template.apigee_instance_group_template.self_link
  }

}

resource "google_compute_health_check" "apigee_instance_hc" {
  project     = module.default.project_id
  name        = "apigee-mig-hc"
  description = "Health check for the Apigee instances, used by the load balancer."
  healthy_threshold   = 2
  unhealthy_threshold = 5

  https_health_check {
    port_name    = "https"
    request_path = "/healthz/ingress"
  }
}

resource "google_compute_region_autoscaler" "default" {
  project = module.default.project_id
  name    = "${var.prefix}-apigee-x-scaler"
  target  = google_compute_region_instance_group_manager.default.id
  region  = var.region

  autoscaling_policy {
    max_replicas    = 20
    min_replicas    = 2
    cooldown_period = 90

    cpu_utilization {
      target = 0.75
    }
  }
}

resource "google_compute_global_address" "https_lb_ip_address" {
  project      = module.default.project_id
  name         = "${var.prefix}-lb-ip-address"
  ip_version   = "IPV4"
  description  = "IP address for the public Load Balancer."
  address_type = "EXTERNAL"
}

resource "google_compute_firewall" "lb_to_mig_access" {
  project     = module.default.project_id
  name        = "lb-mig-access"
  network     = google_compute_network.default.self_link
  description = "Provides access to the Managed Instance Group from the Load Balancer."
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [443]
  }

  source_ranges = [
    "130.244.0.0/22",
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = [
    "gke-apigee-proxy"
  ]
}

resource "google_compute_managed_ssl_certificate" "https_lb_managed_certificate" {
  project     = module.default.project_id
  name        = "apigee-lb-managed-cert"
  description = "SSL Certificate to be attached to the load balancer."

  managed {
    domains = [var.domain]
  }

}

resource "google_compute_backend_service" "apigee_backend_service" {
  project                         = module.default.project_id
  health_checks                   = [google_compute_health_check.apigee_instance_hc.self_link]
  name                            = "${var.prefix}-apigee-be"
  load_balancing_scheme           = "EXTERNAL"
  port_name                       = "https"
  protocol                        = "HTTPS"
  session_affinity                = "NONE"
  timeout_sec                     = 60
  connection_draining_timeout_sec = 300

  backend {
    group = google_compute_region_instance_group_manager.default.instance_group
  }
}


resource "google_compute_url_map" "apigee_be_url_map" {
  project         = module.default.project_id
  name            = "${var.prefix}-apigee-url-map"
  default_service = google_compute_backend_service.apigee_backend_service.self_link
}

resource "google_compute_target_https_proxy" "apigee_target_proxy" {
  project          = module.default.project_id
  name             = "${var.prefix}-apigee-mig-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.https_lb_managed_certificate.self_link]
  url_map          = google_compute_url_map.apigee_be_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "apigee_forwarding_rule" {
  project               = module.default.project_id
  name                  = "${var.prefix}-apigee-be-fwd-rule"
  ip_address            = google_compute_global_address.https_lb_ip_address.address
  target                = google_compute_target_https_proxy.apigee_target_proxy.self_link
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}

/*
resource "google_compute_global_forwarding_rule" "apigee_mig_https_lb_rule" {
  ip_address  = "34.120.45.154"
  ip_protocol = "TCP"
  labels = {
    managed-by-cnrm = "true"
  }
  load_balancing_scheme = "EXTERNAL"
  name                  = "apigee-mig-https-lb-rule"
  port_range            = "443-443"
  project               = "bdb-main-apigee-8d42"
  target                = "https://www.googleapis.com/compute/beta/projects/bdb-main-apigee-8d42/global/targetHttpsProxies/apigee-mig-https-proxy"
}
# terraform import google_compute_global_forwarding_rule.apigee_mig_https_lb_rule projects/bdb-main-apigee-8d42/global/forwardingRules/apigee-mig-https-lb-rule
resource "google_compute_health_check" "hc_apigee_mig_443" {
  check_interval_sec = 5
  healthy_threshold  = 2
  https_health_check {
    port               = 443
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/healthz/ingress"
  }
  name                = "hc-apigee-mig-443"
  project             = "bdb-main-apigee-8d42"
  timeout_sec         = 5
  unhealthy_threshold = 2
}

resource "google_compute_global_address" "lb_ipv4_vip_1" {
  address      = "34.120.45.154"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  labels = {
    managed-by-cnrm = "true"
  }
  name    = "lb-ipv4-vip-1"
  project = "bdb-main-apigee-8d42"
}

resource "google_compute_route" "default_route_39880443b4daa06c" {
  description = "Default local route to the subnetwork 10.100.0.0/28."
  dest_range  = "10.100.0.0/28"
  name        = "default-route-39880443b4daa06c"
  network     = "https://www.googleapis.com/compute/v1/projects/bdb-main-apigee-8d42/global/networks/cf-network"
  project     = "bdb-main-apigee-8d42"
}
# terraform import google_compute_route.default_route_39880443b4daa06c projects/bdb-main-apigee-8d42/global/routes/default-route-39880443b4daa06c
resource "google_compute_network" "cf_network" {
  name         = "cf-network"
  project      = "bdb-main-apigee-8d42"
  routing_mode = "REGIONAL"
}
# terraform import google_compute_network.cf_network projects/bdb-main-apigee-8d42/global/networks/cf-network
resource "google_compute_router" "rtr_egress_traffic" {
  bgp {
    advertise_mode = "DEFAULT"
    asn            = 64514
  }
  name    = "rtr-egress-traffic"
  network = "https://www.googleapis.com/compute/v1/projects/bdb-main-apigee-8d42/global/networks/cf-network"
  project = "bdb-main-apigee-8d42"
  region  = "europe-west2"
}

resource "google_compute_route" "peering_route_668f949ec29fd606" {
  description = "Auto generated route via peering [servicenetworking-googleapis-com]."
  dest_range  = "10.136.8.0/28"
  name        = "peering-route-668f949ec29fd606"
  network     = "https://www.googleapis.com/compute/v1/projects/bdb-main-apigee-8d42/global/networks/cf-network"
  project     = "bdb-main-apigee-8d42"
}

resource "google_compute_url_map" "apigee_mig_proxy_map" {
  default_service = "https://www.googleapis.com/compute/v1/projects/bdb-main-apigee-8d42/global/backendServices/apigee-mig-backend"
  name            = "apigee-mig-proxy-map"
  project         = "bdb-main-apigee-8d42"
}


*/