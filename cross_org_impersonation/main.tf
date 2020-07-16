module "main_bootstrap" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 8.0"

  name                = ""
  random_project_id   = true
  org_id              =
  billing_account     =
  folder_id           =
  skip_gcloud_download = true
}