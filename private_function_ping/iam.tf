resource "google_organization_iam_member" "xpn_admin" {
  org_id = var.organization_id

  member = "user:${var.user_id}"
  role = "roles/compute.xpnAdmin"
}