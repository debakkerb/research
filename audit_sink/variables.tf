variable "billing_account" {}
variable "folder_id" {
  description = "Parent of the project with the log sink."
  default     = null
}
variable "organization_id" {
  description = "Parent of the project with the log sink."
  default     = null
}
