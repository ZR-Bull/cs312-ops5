output "cs312-ops5-public_ip" {
  description = "Public IP of the main ops5 instance"
  value       = aws_instance.cs312-ops5.public_ip
}