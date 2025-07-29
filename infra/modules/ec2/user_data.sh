#!/bin/bash

# User Data Script for Flask Microservices
# Environment: ${environment}

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    unzip \
    htop \
    tree

# Set password for ubuntu user
echo "ubuntu:${password}" | chpasswd

# Configure SSH
# sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config


# Setup SSH key if provided
if [ -n "${ssh_key}" ]; then
    mkdir -p /home/ubuntu/.ssh
    echo "${ssh_key}" >> /home/ubuntu/.ssh/authorized_keys
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
    chmod 600 /home/ubuntu/.ssh/authorized_keys
fi

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-get update
apt-get install -y docker.io

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install MySQL client
apt-get install -y mysql-client-core-8.0

# Create application directories
mkdir -p /home/ubuntu/apps
mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/backups

# Set proper permissions
chown -R ubuntu:ubuntu /home/ubuntu

# Configure system limits for Docker
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Create systemd service for Docker Compose (optional)
cat > /etc/systemd/system/docker-compose@.service << EOF
[Unit]
Description=Docker Compose Application Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/apps/%i
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Restart SSH service
systemctl restart sshd

# Create welcome message
cat > /home/ubuntu/welcome.txt << EOF
==========================================
Flask Microservices Environment: ${environment}
==========================================

System Information:
- Ubuntu 22.04 LTS
- Docker: $(docker --version)
- Docker Compose: $(docker-compose --version)

Application Directories:
- Apps: /home/ubuntu/apps
- Logs: /home/ubuntu/logs
- Backups: /home/ubuntu/backups

Useful Commands:
- Check containers: docker ps
- View logs: docker logs <container_name>
- Restart services: docker-compose restart
- System status: systemctl status docker

SSH Access:
- User: ubuntu
- Password: ${password}
EOF

chown ubuntu:ubuntu /home/ubuntu/welcome.txt

# Display welcome message
cat /home/ubuntu/welcome.txt

echo "User data script completed successfully!" 