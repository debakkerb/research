/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


terraform {
  required_version = "~> 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.81"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.81"
    }
  }

  backend "gcs" {
    bucket = "${bucket_name}"
    prefix = "${prefix}"
  }
}

data "google_service_account_access_token" "default" {
  provider               = google.impersonated
  scopes                 = ["userinfo-email", "cloud-platform"]
  target_service_account = "${bootstrap_service_account_email}"
  lifetime               = "1800s"
}

provider "google" {
  alias = "impersonated"
}

provider "google-beta" {
  alias = "impersonated"
}

provider "google" {
  region            = var.region
  zone              = var.zone
  access_token      = data.google_service_account_access_token.default.access_token
}

provider "google-beta" {
  region            = var.region
  zone              = var.zone
  access_token      = data.google_service_account_access_token.default.access_token
}