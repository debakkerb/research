provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "eu-west-1"
}

provider "google" {}
provider "google-beta" {}