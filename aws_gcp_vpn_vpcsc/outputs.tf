output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.bastion_host.public_ip}"
}

output "gcp_project_id" {
  value = google_project.gcp_project.project_id
}

output "gcp_project_nmbr" {
  value = google_project.gcp_project.number
}