# Static Webhosting

The purpose of this demo is to host a static website in Google Cloud Storage, with protected resources.  
Protection is done via Identity Aware Proxy and Cloud Run. It follows more or
less [this guide](https://cloud.google.com/community/tutorials/securing-gcs-static-website), but the difference is that
the Cloud Run endpoint is protected with the Identity Aware Proxy and does not serve a Login page itself.

## DISCLAIMER

This is a demo and example and shouldn't be treated as production-ready code.  It's your responsibility to ensure that this complies with internal processing and requirements.

## Installation instructions

Create a `terraform.tfvars`-file in this directory with the following content:

```hcl
billing_account_id      = "123456-123456-123456"
folder_id               = "0123456789"
organization_id         = "0123456789"
cors_origin             = ["https://static-hosting-domain"]
ssl_domain_names        = ["static-hosting-domain"]
login_service_access    = ["user:john.doe@acme.com"]
brand_application_title = "Name of Static Host"
brand_support_email     = "john.doe@acme.com"
iap_client_display_name = "Name of Static Host"
```

### Variables

Please refer to `variables.tf` for more information on what these variables are and which other variables can be
overridden.

#### terraform.tfvars

| Name                      | Description                                                                                                                                                                                                                |
|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cors_origin`             | Used for the storage bucket, domain which is allowed to send requests to the bucket.                                                                                                                                       |
| `ssl_domain_names`        | These are the domain names used for the managed SSL certificates.                                                                                                                                                          |
| `login_service_access`    | List of identities who require access to the service.  Can be a combination of anything, just make sure the type is added as a prefix.  So, for example, `[ "user:john.doe@acme.com", "group:service-accessors@acme.com"]` |
| `brand_application_title` | Title of the application that is shown to users when the IAP login results in an error                                                                                                                                     |
| `brand_support_email`     | Email address of the developer or support.  This address is publicly shown when access is denied to the underlying resource.                                                                                               |
| `iap_client_display_name` | Display that is shown on the error page when a client is denied access to the underlying resource.                                                                                                                         |

### Create Infrastructure
The application requires a key to sign the Cookie, for the underlying CDN endpoint.  I recommend rotating the key via the command line on a regular basis.

```shell
SIGNING_KEY=$(head -c 16 /dev/urandom | base64 | tr +/ -_)

# Init Terraform
terraform init -upgrade -reconfigure

# Apply the changes
terraform apply -auto-approve -var="cdn_signing_key=${SIGNING_KEY}"

# Store the signing key in secret manager
printf "${SIGNING_KEY}" | gcloud secrets versions add [SECRET_NAME] --data-file=-
```

Even though the CDN signing key is sensitive, it will end up in the Terraform state this way.  It's not recommended to do this in a PRD environment, so a better approach is to generate the key outside of the Terraform code and push it to Secret Manager directly:

```shell
echo "$(head -c 16 /dev/urandom | base64 tr +/ -_)" | \
  gcloud secret versions add [SECRET_ID] --data-file=- --project [PROJECT_ID] 
```

When everything is created, it will take a while for the SSL certificate to be generated, signed and generally made available.  You can check the status of the SSL certificate by running the following command:

```shell
gcloud compute ssl-certificates describe $(terraform output -json | jq -r .ssl_certificate_name.value) --format "value(managed.status)
```

Status should be `ACTIVE` before you can send requests to the SSL endpoint.

