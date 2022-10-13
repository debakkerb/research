# Application

The purpose of this application is to generate a signed cookie for a CDN endpoint.  It requires access to the signing key that is also used by the backend.  For building the container, [Google Buildpacks](https://github.com/GoogleCloudPlatform/buildpacks) are used for increased safety.

To use this module, simply add the following to your Terraform code:

```hcl
module "application" {
  source = "./modules/login-app"
  
  project_id = "<YOUR_PROJECT_ID>"
  image_tag  = "<YOUR_IMAGE_TAG>"
  image_name = "<YOUR_IMAGE_NAME>"
}
```

