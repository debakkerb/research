# HA VPN Tunnel

This research was put together by following the [official documentation](https://cloud.google.com/vpn/docs/how-to/creating-ha-vpn2) and a Terraform code [https://www.terraform.io/docs/providers/google/r/compute_ha_vpn_gateway.html](example).

## TL;DR
When creating the Interface and Peer resources, the Peering IP address has to come out of the IP range configured on the other end.  For the VM in project 2 to access GCS (= public API), private access has to be enabled on the Subnet.

## Architecture
![HA VPN Architecture](./architecture/ha_vpn_architecture.png)

## Resources
The Terraform files create the 
