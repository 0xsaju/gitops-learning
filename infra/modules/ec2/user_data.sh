#!/bin/bash
# User Data Script for Flask Microservices
# Environment: ${environment}
set -e

# Add logging for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1
echo "Starting user data script at $(date)"

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
    tree \
    gnupg \
    lsb-release

# Set password for ubuntu user
echo "ubuntu:${password}" | chpasswd
echo "Password set for ubuntu user at $(date)"

# Configure SSH for key-based authentication
echo "Configuring SSH for key-based authentication..."

# Enable public key authentication
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

# Disable password authentication for security
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Ensure SSH directory exists
mkdir -p /home/ubuntu/.ssh

echo "SSH configuration updated at $(date)"
echo "Current SSH config:"
grep -E "(PasswordAuthentication|PubkeyAuthentication|AuthorizedKeysFile)" /etc/ssh/sshd_config || echo "No SSH config found"

# Setup SSH key
echo "Setting up SSH key for key-based authentication..."
cat > /home/ubuntu/.ssh/authorized_keys << 'SSHKEY'
${ssh_key}
SSHKEY
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
echo "SSH key configured at $(date)"

# Install Docker
echo "Installing Docker..."
# Remove any old Docker installations
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
apt-get update

# Install Docker Engine
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose (standalone version for compatibility)
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install MySQL client
apt-get install -y mysql-client-core-8.0

# Create application directories
mkdir -p /home/ubuntu/staging-app
mkdir -p /home/ubuntu/production-app
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

# Verify Docker installation
echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker-compose --version

# Create systemd service for Docker Compose (optional)
cat > /etc/systemd/system/docker-compose@.service << EOF
[Unit]
Description=Docker Compose Application Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/%i
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Verify SSH configuration before restarting
echo "Current SSH configuration:"
grep -E "(PasswordAuthentication|PubkeyAuthentication|AuthorizedKeysFile)" /etc/ssh/sshd_config

# Test SSH configuration syntax
sshd -t
if [ $? -eq 0 ]; then
    echo "SSH configuration syntax is valid"
    # Restart SSH service
    systemctl restart sshd
    echo "SSH service restarted at $(date)"
else
    echo "SSH configuration has syntax errors!"
    exit 1
fi

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
- Staging: /home/ubuntu/staging-app
- Production: /home/ubuntu/production-app
- Logs: /home/ubuntu/logs
- Backups: /home/ubuntu/backups

Useful Commands:
- Check containers: docker ps
- View logs: docker logs <container_name>
- Restart services: docker-compose restart
- System status: systemctl status docker

SSH Access:
- User: ubuntu
- Authentication: SSH key only

EOF

chown ubuntu:ubuntu /home/ubuntu/welcome.txt

# Display welcome message
cat /home/ubuntu/welcome.txt

echo "User data script completed successfully at $(date)!"
echo "System is ready for Ansible deployment."