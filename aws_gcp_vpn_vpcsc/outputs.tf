output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.default.public_ip}"
}