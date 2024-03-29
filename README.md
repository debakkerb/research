# Terraform research

This repository contains a number of scripts which have been used to investigate GCP installations.  They are not routinely updated, so a lot of them will probably be outdated.  However, it should give the reader an idea what to do, what resources were used and how they were configured.

This code deliberately doesn't use modules, to show all the resources that have been created to achieve this result.  It's not intended to be used in PRD use, but to use as a guide on what resources are being used and how they are configured.

## Scenarios
* [Cloud SQL Proxy](./cloud-sql-proxy)
* [Google App Engine with Private Cloud SQL](./gae_private_cloud_sql_iap)
* [HTTPS Load Balancer with Managed Instance Group](./https_lb_mig)
* [GKE Cluster in Shared VPC](./private_gke_shared_vpc)