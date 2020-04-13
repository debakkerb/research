# HA VPN Tunnel

This research was put together by following the [official documentation](https://cloud.google.com/vpn/docs/how-to/creating-ha-vpn2) and a Terraform code [https://www.terraform.io/docs/providers/google/r/compute_ha_vpn_gateway.html](example).

## TL;DR
When creating the Interface and Peer resources, the Peering IP address has to come out of the IP range configured on the other end.  For the VM in project 2 to access GCS (= public API), private access has to be enabled on the Subnet.

## Architecture
![HA VPN Architecture](./architecture/ha_vpn_architecture.png)

There is 1 Bastion host, that allows access on port 22, to allow SSH access.  The second VM only allows access to the SA in use by the Bastion host, to ensure no other VMs can login.  Thanks to Private Access, the second VM can access the GCS bucket.

## Resources
The Terraform files create the following resources:
* 2 Projects.
* 2 Networks, 1 in each project.
* 4 Subnets, 2 in each project.
* 2 Cloud Routers, 1 in each project.
* 2 VPN Gateways, 1 in each project.
* 4 VPN tunnels, 2 between each gateway.
* 2 VMs, 1 in each project.
* GCS bucket, only accessible over private access.
* 2 Service Accounts, 1 for each VM.

### Projects
Projects were created by using the Project module in tf-modules.  For more information, please refer to that repository. Only `compute.googleapis.com` has to be enabled for this setup.

### Networks
#### Network 1

```hcl-terraform
resource "google_compute_network" "public_vpc_1" {
  name                    = "public-vpc-1"
  project                 = module.project_vpc_1.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public_subnet_1" {
  ip_cidr_range = "10.0.0.0/24"
  name          = "sn-eu-west-1"
  network       = google_compute_network.public_vpc_1.self_link
  region        = "europe-west1"
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_1.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "public_subnet_2" {
  ip_cidr_range = "10.0.1.0/24"
  name          = "sn-eu-west-2"
  network       = google_compute_network.public_vpc_1.self_link
  region        = "europe-west2"
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_1.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
```

#### Network 2
```hcl-terraform
resource "google_compute_network" "private_vpc_2" {
  name                    = "private-vpc-2"
  project                 = module.project_vpc_2.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet_1" {
  ip_cidr_range = "10.0.2.0/24"
  name          = "sn-eu-west-1"
  region        = "europe-west1"
  network       = google_compute_network.private_vpc_2.self_link
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_2.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnet_2" {
  ip_cidr_range = "10.0.3.0/24"
  name          = "sn-eu-west-3"
  region        = "europe-west3"
  network       = google_compute_network.private_vpc_2.self_link
  description   = "Subnet which will be connected to the other network via VPN"

  project = module.project_vpc_2.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}
```





