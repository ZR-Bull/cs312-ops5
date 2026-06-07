terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Use the default VPC instead of creating a new one
data "aws_vpc" "default" {
  default = true
}

# Security Group: Strict control for SSH and Minecraft
resource "aws_security_group" "cs312-ops4-sg" {
  name        = "cs312-ops4-sg"
  description = "Security group for Ops4. SSH (port 22) and Minecraft (port 25565)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from known source"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to your own IP for better security.
  }

  ingress {
    description = "Minecraft"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cs312-ops4-sg"
  }
}

# EC2 instance running Ubuntu 24.04 (t3.medium for sufficient JVM memory heap space)
resource "aws_instance" "cs312-ops4" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.cs312-ops4-sg.id]
  iam_instance_profile   = "LabInstanceProfile"

  tags = {
    Name = "cs312-ops4"
  }
}

# Generate local Ansible inventory file dynamically
resource "local_file" "ansible_inventory" {
  content  = <<EOT
[managed]
ec2 ansible_host=${aws_instance.cs312-ops4.public_ip} ansible_user=ubuntu

[managed:vars]
ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
EOT
  filename = "hosts.ini"
}

# Automation trigger to bootstrap k3s on our host
resource "null_resource" "ansible_trigger" {
  depends_on = [aws_instance.cs312-ops4, local_file.ansible_inventory]

  provisioner "local-exec" {
    command = "sleep 30 && ansible-playbook -i hosts.ini playbook.yml"
  }
}