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
  # To use a named profile instead of default, add: profile = "profile-name"
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
  instance_type          = "t3.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  iam_instance_profile = "LabInstanceProfile"

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
    cidr_blocks = ["0.0.0.0/0"] # TODO: Figure out my IP later
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

