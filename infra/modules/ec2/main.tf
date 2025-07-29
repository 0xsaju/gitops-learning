data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "main" {
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = var.encrypt_volumes
  }

  user_data_base64 = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    ssh_key     = var.ssh_public_key
    password    = var.instance_password
    timestamp   = timestamp()
  }))

  tags = merge(var.common_tags, {
    Name = "${var.environment}-flask-microservices"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "main" {
  count    = var.allocate_eip ? 1 : 0
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-eip"
  })
}