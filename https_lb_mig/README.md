# HTTPS Load Balancer with MIG

This folder will explore how to create an HTTPS load balancer, fronting a workload hosted on a Managed Instance Group.  The reason why I put this together is because quite a few resources are involved and it's not always clear what they do or what the purpose is.  If you follow along with the documentation, most of the information is scattered across different links, which makes it difficult to understand what is happening at each step.

As mentioned in the overall README-page, I'm deliberately not using any Terraform modules, so that you clearly understand what resources are being used and how these are configured.  

## Resources

Global load balancers on GCP use an Anycast IP to target underlying services.  The path a request follows can be summarized as:

Public IP => Forward Rule => Target Proxy => URL Map => Backend => Managed Instance Group

This is a lot to take in, but once you understand each individual component, it makes the overall picture more comprehensible.

### Public IP
As mentioned, a public IP address is needed so it can be attached to the external HTTPS load balancer.  This can either be an IP address that already exists or an IP address that is reserved in GCP.  Both IPv4 and IPv6 are supported.  When creating an A record for your DNS domain, this is the IP address to use as the target.

```terraform
resource "google_compute_global_address" "https_lb_ip_address" {
  project      = module.project.project_id
  name         = "${var.prefix}-lb-ip-address"
  ip_version   = "IPV4"
  description  = "IP address for the public Load Balancer."
  address_type = "EXTERNAL"
}
```

### Forwarding Rule

This is the IP address + port(s) on wich the LB will accept traffic.  In terms of protocol, both TCP and UDP are supported.  Be careful when configuring `load_balancing_scheme`, as it defines where traffic will be forwarded **from**.  This means that setting it to `INTERNAL` means that you only accept traffic from traffic that originated within the same VPC or a connected VPC.

```terraform
resource "google_compute_global_forwarding_rule" "https_lb_fwd_rule" {
  project               = module.project.project_id
  name                  = "${var.prefix}-lb-fwd-rule"
  ip_address            = google_compute_global_address.https_lb_ip_address.address
  target                = google_compute_target_https_proxy.target_proxy.self_link
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}
```

### Target Proxy

The target proxy is referenced by the forwarding rules and it defines where requests can be sent to.  It's main purpose is to redirect incoming requests to a URL map that is defined in the environment.

```terraform
resource "google_compute_target_https_proxy" "target_proxy" {
  project          = module.project.project_id
  name             = "${var.prefix}-mig-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.https_lb_managed_certificate.self_link]
  url_map          = google_compute_url_map.url_map.self_link
}
```

In this example, I'm using a Google managed SSL certificate, but it's perfectly fine to bring your own if you have one.

### URL Map

The purpose of the URL map is to define a list of backends that can receive requests.  Given that we are creating an L7 load balancer, this can be done based on paths.  E.g. /video should be sent to a particular backend server.  For this example, I've created a simple backend and have not made distinctions between requests.  

```terraform
resource "google_compute_url_map" "url_map" {
  project         = module.project.project_id
  name            = "${var.prefix}-url-map"
  default_service = google_compute_backend_service.backend_service.self_link
}
```

### Backend Service

The backend service(s) are the resources that host the actual workloads.

```terraform
resource "google_compute_backend_service" "backend_service" {
  project                         = module.project.project_id
  health_checks                   = [google_compute_health_check.backend_health_check.self_link]
  name                            = "${var.prefix}-backend"
  load_balancing_scheme           = "EXTERNAL"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 60
  connection_draining_timeout_sec = 300

  backend {
    group = google_compute_region_instance_group_manager.default.instance_group
  }

  log_config {
    enable = true
  }
}
```


