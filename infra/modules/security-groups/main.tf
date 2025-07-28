resource "aws_security_group" "main" {
  vpc_id = var.vpc_id
  name   = "${var.environment}-security-group"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr_blocks
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr_blocks
    description = "HTTPS access"
  }

  # Flask microservices ports
  ingress {
    from_port   = 5001
    to_port     = 5003
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr_blocks
    description = "Flask microservices (User, Product, Order APIs)"
  }

  # Frontend port
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr_blocks
    description = "Frontend application"
  }

  # Database ports (if needed for external access)
  dynamic "ingress" {
    for_each = var.expose_database_ports ? [1] : []
    content {
      from_port   = 32000
      to_port     = 32002
      protocol    = "tcp"
      cidr_blocks = var.allowed_database_cidr_blocks
      description = "MySQL databases (User, Product, Order)"
    }
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-security-group"
  })
} 