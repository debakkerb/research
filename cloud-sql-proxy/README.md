# Cloud SQL Proxy

In order to connect to a Cloud SQL instance with a private IP address, you can use the [Cloud SQL proxy](https://github.com/GoogleCloudPlatform/cloudsql-proxy).  It's not possible to run this on your local machine, as the proxy requires access to the private IP address.  To solve that, you can run it on a VM and use that as a jump box to connect to the Cloud SQL instance.

![Cloud SQL Proxy](diagrams/cloud_sql_proxy.png)

To make this example more realistic, we run the Cloud SQL instance in a Shared VPC, as this is normally the setup most Enterprise customers have configured. This way, we can clearly share what resources are running in which project (host and service).  