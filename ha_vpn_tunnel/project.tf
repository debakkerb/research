module "project_vpc_1" {
  source = "git@github.com:debakkerb/tf-modules//10_-_standalone/project"

  billing_account_id = local.billing_account_id
  folder_id          = local.sandbox_folder_id

  project_name = "bdb-vpn-vpc-1"

  project_services = [
    "compute.googleapis.com"
  ]
}

module "project_vpc_2" {
  source = "git@github.com:debakkerb/tf-modules//10_-_standalone/project"

  billing_account_id = local.billing_account_id
  folder_id          = local.sandbox_folder_id

  project_name = "bdb-vpn-vpc-2"

  project_services = [
    "compute.googleapis.com"
  ]
}