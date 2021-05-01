# Cloud SQL Proxy

In order to connect to a Cloud SQL instance with a private IP address, you can use the [Cloud SQL proxy](https://github.com/GoogleCloudPlatform/cloudsql-proxy).  It's not possible to run this on your local machine, as the proxy requires access to the private IP address.  To solve that, you can run it on a VM and use that as a jump box to connect to the Cloud SQL instance.

![Cloud SQL Proxy](diagrams/cloud_sql_proxy.png)

To make this example more realistic, we run the Cloud SQL instance in a Shared VPC, as this is normally the setup most Enterprise customers have configured. This way, we can clearly share what resources are running in which project (host and service).  

## How To Run

### Create

Create a `terraform.tfvars`-file in this directory, with the following variables:

| Variable           |  Type  | Description                                                                                                                          |
|--------------------|:------:|--------------------------------------------------------------------------------------------------------------------------------------|
| organization_id    | string | The ID of the GCP organization.                                                                                                      |
| billing_account_id | string | ID of the Billing Account.                                                                                                           |
| parent_folder_id   | string | The ID of the parent folder.                                                                                                         |
| identity           | string | The user id of the person who is running the Terraform commands. This is the identity who will be accessing the proxy and database.  |
| prefix             | string | The prefix that will be used for nearly all resources.  This will be the prefix for the project names and IDs, amongst other things. |

Run the following commands to create the target environment.

```shell
# Initialise Terraform in this directory
terraform init

# Apply Terraform
terraform apply -auto-approve
```

This will create all the resources, depicted in the diagram.  It will also create a `backend.tf`-file, which contains the necessary information to copy your Terraform state to a GCS bucket.  If you want that, you will have to run `terraform init` again in the same directory and input `yes` when asked to copy the state remotely.  However, if you want to skip that, there is no need to execute that last step.

### Access

To access the environment, open two terminal windows and run the following commands:
1. IAP Tunnel: `$(terraform output -json | jq -r .start_iap_tunnel.value)`
2. PSQL: `terraform tf output -json | jq -r .sql_client_command.value | pbcopy`

Because of the double quotes, the command is copied to your cache and you can paste it in the terminal window. To retrieve the password for the database, run `$(terraform output -json | jq -r .retrieve_db_password.value) | pbcopy` and copy/paste it where you ran the `PSQL`-command (second terminal).

### Destroy

To destroy the environment, remove `backend.tf` and re-initialise terraform again.  When asked to copy the remote state to your local environment, enter `yes`.  Once done, run `terraform destroy -auto-approve`.  This will tear down the entire environment.

## Variables



## Resources