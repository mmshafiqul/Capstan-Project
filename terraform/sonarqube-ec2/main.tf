data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

resource "aws_security_group" "sonarqube" {
  name_prefix = "${var.name_prefix}-sonarqube-"
  description = "SonarQube EC2 security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "SonarQube UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" "sonarqube" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.sonarqube.id]
  associate_public_ip_address = true

  key_name = var.ssh_key_name != "" ? var.ssh_key_name : null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail

    # SonarQube requires this for Elasticsearch.
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" > /etc/sysctl.d/99-sonarqube.conf

    dnf update -y
    dnf install -y docker
    systemctl enable --now docker

    # Run SonarQube (Community). Exposes :9000 on the instance.
    docker run -d --name sonarqube \
      --restart unless-stopped \
      -p 9000:9000 \
      -v sonarqube_data:/opt/sonarqube/data \
      -v sonarqube_extensions:/opt/sonarqube/extensions \
      -v sonarqube_logs:/opt/sonarqube/logs \
      sonarqube:lts-community
  EOT

  tags = merge(var.tags, { Name = "${var.name_prefix}-sonarqube" })
}
