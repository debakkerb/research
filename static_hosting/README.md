# Static Webhosting

The purpose of this demo is to host a static website in Google Cloud Storage, with protected resources.  
Protection is done via Identity Aware Proxy and Cloud Run. It follows more or
less [this guide](https://cloud.google.com/community/tutorials/securing-gcs-static-website), but the difference is that
the Cloud Run endpoint is protected with the Identity Aware Proxy and does not serve a Login page itself.

## Installation instructions

Create a `terraform.tfvars`-file in this directory with the following content:

```hcl
billing_account_id      = "123456-123456-123456"
folder_id               = "0123456789"
organization_id         = "0123456789"
storage_bucket_name     = "static-hosting-domain"
cors_origin             = ["https://static-hosting-domain"]
ssl_domain_names        = ["static-hosting-domain"]
login_service_access    = ["user:john.doe@acme.com"]
brand_application_title = "Name of Static Host"
brand_support_email     = "john.doe@acme.com"
iap_client_display_name = "Name of Static Host"
```

Please refer to `variables.tf` for more information on what these variables are and which other variables can be
overridden.

Create all the GCP resources by running the following command:

```shell
terraform apply -auto-approve -var="cdn_signing_key=$(head -c 16 /dev/urandom | base64 | tr +/ -_)"
```

Even though the CDN signing key is sensitive, it will end up in the Terraform state this way.  It's not recommended to do this in a PRD environment, so a better approach is to generate the key outside of the Terraform code and push it to Secret Manager directly:

```shell
echo "$(head -c 16 /dev/urandom | base64 tr +/ -_)" | \
  gcloud secret versions add [SECRET_ID] --data-file=- --project [PROJECT_ID] 
```

When everything is created, it will take a while for the SSL certificate to be generated, signed and generally made available.  You can check the status of the SSL certificate by running the following command:

```shell
gcloud compute ssl-certificates list --project $PROJECT_ID | grep ${DNS_NAME}
```

Status should be `ACTIVE` before you can send requests to the SSL endpoint.

