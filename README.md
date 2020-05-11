# Terraform research

This repository contains a number of scripts which have been used to investigate GCP installations.  They are not routinely updated, so a lot of them will probably be outdated.  However, it should give the reader an idea what to do, what resources were used and how they were configured.

This code deliberately doesn't use modules, to show all the resources that have been created to achieve this result.  It's not intended to be used in PRD use, but to use as a guide on what resources are being used and how they are configured.

## Scenarios
* [Impersonating Service Accounts for Build Pipelines](./service_account_impersonation)
* [Cloud Function Private Healthcheck](./private_function_ping)
* [HA VPN](./ha_vpn_tunnel/)
* [Log Export Sinks](./org_sink_export/)
* [DNS Hub and Spoke](./dns_hub_spoke)
* [Audit Sinks](./audit_sink)
* [VPC SC](./vpc_sc)
