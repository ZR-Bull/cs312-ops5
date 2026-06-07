output "cs312-ops4-public_ip" {
  description = "Public IP of the main ops4 instance"
  value       = aws_instance.cs312-ops4.public_ip
}