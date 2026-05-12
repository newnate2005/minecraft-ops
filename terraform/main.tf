terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.41.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  common_tags = {
    Owner = var.onid
  }
}

resource "aws_instance" "minecraft" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  iam_instance_profile = "LabInstanceProfile"
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "minecraft-server"
  })
}

resource "aws_security_group" "minecraft" {
  name        = "minecraft-sg"
  description = "Allow SSH and Minecraft"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH admin access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["50.38.104.203/32"]
  }

  ingress {
    description = "Minecraft clients"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "minecraft-sg"
  })
}

resource "null_resource" "ansible" {
  depends_on = [aws_instance.minecraft]

  triggers = {
    instance_id = aws_instance.minecraft.id
  }

  provisioner "local-exec" {
    command = <<EOT
      # Wait for SSH to be available
      until ssh -i ~/.ssh/cs312-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@${aws_instance.minecraft.public_ip} echo ready; do
        sleep 5
      done
      # Update hosts.ini
      echo "[minecraft]" > ../ansible/hosts.ini
      echo "${aws_instance.minecraft.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/cs312-key.pem" >> ../ansible/hosts.ini
      # Run playbook
      cd ../ansible && ansible-playbook playbook.yml
    EOT
  }
}

