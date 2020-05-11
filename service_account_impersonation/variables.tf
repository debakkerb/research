variable "organization_id" {
  description = "Organization ID that should be the parent for this project."
  default     = null
}

variable "folder_id" {
  description = "Folder ID that should be the parent of this project."
  default     = null
}

variable "billing_account" {
  description = "The billing account to link to this project."
}

variable "user_id" {
  description = "Identity of the user executing the script."
}