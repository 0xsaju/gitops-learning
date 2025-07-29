output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "eip_public_ip" {
  description = "Elastic IP address if allocated"
  value       = var.allocate_eip ? aws_eip.main[0].public_ip : null
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = var.allocate_eip ? "ssh ubuntu@${aws_eip.main[0].public_ip}" : "ssh ubuntu@${aws_instance.main.public_ip}"
}