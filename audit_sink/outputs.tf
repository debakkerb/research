output "project_id" {
  value = google_project.audit_sink_project.project_id
}

output "project_number" {
  value = google_project.audit_sink_project.number
}

output "pet" {
  value = random_pet.randomizer.id
}