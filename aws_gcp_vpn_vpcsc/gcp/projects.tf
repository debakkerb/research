module "common_services_network" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 8.0"

  name                = "common-svc-network"
  random_project_id   = true
  org_id              = var.organization_id
  billing_account     = var.billing_account_id
  folder_id           = var.parent_id
  skip_gcloud_download = true
  activate_apis = [
    "compute.googleapis.com"
  ]
}

module "workload_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 8.0"

  name                = "gcp-workloads"
  random_project_id   = true
  org_id              = var.organization_id
  billing_account     = var.billing_account_id
  folder_id           = var.parent_id
  skip_gcloud_download = true
  activate_apis = [
    "compute.googleapis.com"
  ]
}