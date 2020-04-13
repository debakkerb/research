# Image
data "google_compute_image" "debian" {
  family  = "debian-9"
  project = "debian-cloud"
}