variable "folder_id" {
  description = "Parent folder ID for the project."
  default     = null
}

variable "organization_id" {
  description = "Organization ID that will act as a parent for the project."
  default     = null
}
variable "billing_account" {
  description = "Billing Account to link to the project."
}

variable "user_id" {
  description = "User ID of the person running this Terraform script."
}
