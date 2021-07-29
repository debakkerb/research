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

This is the IP address + port(s) on wich the LB will accept traffic.  In terms of protocol, both TCP and UDP are supported.  Be careful if 