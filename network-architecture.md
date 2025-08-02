# 🌐 Network Architecture Documentation

## 📋 **Table of Contents**

1. [Network Overview](#network-overview)
2. [Infrastructure Components](#infrastructure-components)
3. [Traffic Flow Analysis](#traffic-flow-analysis)
4. [Security Architecture](#security-architecture)
5. [Docker Networking](#docker-networking)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [Performance Optimization](#performance-optimization)
8. [Monitoring & Observability](#monitoring--observability)

---

## 📡 **1. Network Overview**

Our infrastructure uses a **multi-layered network architecture** with AWS VPC (Virtual Private Cloud) as the foundation:

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS VPC                                │
│                    (10.0.0.0/16)                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Public Subnet  │  │  Private Subnet │  │  Private Subnet │ │
│  │   (10.0.1.0/24) │  │   (10.0.2.0/24) │  │   (10.0.3.0/24) │ │
│  │                 │  │                 │  │                 │ │
│  │  ┌─────────────┐ │  │  ┌─────────────┐ │  │  ┌─────────────┐ │ │
│  │  │    EC2      │ │  │  │   Future    │ │  │  │   Future    │ │ │
│  │  │  Instance   │ │  │  │  Services   │ │  │  │  Services   │ │ │
│  │  │             │ │  │  │             │ │  │  │             │ │ │
│  │  │ 54.254.243.70│ │  │  │             │ │  │  │             │ │ │
│  │  └─────────────┘ │  │  └─────────────┘ │  │  └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### **Key Network Components:**

- **VPC**: Virtual Private Cloud (10.0.0.0/16)
- **Public Subnets**: Direct internet access (10.0.1.0/24, 10.0.2.0/24)
- **Private Subnets**: NAT gateway access (10.0.3.0/24, 10.0.4.0/24)
- **Internet Gateway**: Provides internet connectivity
- **NAT Gateway**: Outbound internet access for private subnets
- **Security Groups**: Firewall rules at instance level

---

## 🏗️ **2. Infrastructure Components**

### **A. VPC (Virtual Private Cloud)**

**Purpose**: Logically isolated section of AWS cloud
**CIDR Block**: 10.0.0.0/16 (65,536 IP addresses)

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

**Benefits**:
- Complete control over networking environment
- Isolated from other AWS customers
- Customizable IP address ranges
- DNS resolution support

### **B. Subnets**

**Public Subnets** (10.0.1.0/24, 10.0.2.0/24):
- Direct internet access via Internet Gateway
- Auto-assign public IPs
- Used for load balancers, bastion hosts

**Private Subnets** (10.0.3.0/24, 10.0.4.0/24):
- No direct internet access
- Access internet via NAT Gateway
- Used for application servers, databases

```hcl
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}
```

### **C. Internet Gateway**

**Purpose**: Provides internet connectivity to VPC
**Configuration**:
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

### **D. NAT Gateway**

**Purpose**: Allows private subnets to access internet
**Configuration**:
```hcl
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}
```

### **E. Route Tables**

**Public Route Table**:
```hcl
resource "aws_route_table" "public" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
```

**Private Route Table**:
```hcl
resource "aws_route_table" "private" {
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}
```

---

## 🔄 **3. Traffic Flow Analysis**

### **Scenario 1: User Accessing Frontend**

```
1. 🌐 User types: http://54.254.243.70:8080
   ↓
2. 📡 DNS resolves to AWS
   ↓
3. 🌍 Internet Gateway receives request
   ↓
4. 🛡️ Security Group checks rules
   ✅ Port 8080 allowed from 0.0.0.0/0
   ↓
5. 🖥️ EC2 Instance receives on port 8080
   ↓
6. 🐳 Docker forwards to Frontend container
   ↓
7. 🎯 Frontend serves HTML/CSS/JS
   ↓
8. 📤 Response flows back through same path
```

### **Scenario 2: Frontend Calling User Service API**

```
1. 🎯 Frontend needs user data
   ↓
2. 🐳 Makes HTTP request to: http://user-service:5001/api/users
   ↓
3. 🐳 Docker DNS resolves "user-service" to 172.17.0.3
   ↓
4. 📡 Internal Docker network communication
   ↓
5. 🎯 User Service receives request
   ↓
6. 🗄️ User Service queries MySQL (172.17.0.4:3306)
   ↓
7. 🐳 MySQL returns user data
   ↓
8. 📤 User Service returns JSON response
   ↓
9. 🔄 Frontend receives and displays data
```

### **Scenario 3: External API Access**

```
1. 🌐 External client calls: http://54.254.243.70:5001/health
   ↓
2. 🐳 Request reaches EC2 instance
   ↓
3. 🛡️ Security Group allows port 5001
   ↓
4. 🐳 Docker forwards to User Service container
   ↓
5. 🎯 User Service responds with health status
   ↓
6. 📤 Response: {"database":"connected","service":"user-service","status":"healthy"}
```

### **Packet Flow Analysis**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              PACKET FLOW                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  📦 Outgoing Packet:                                                         │
│  Source: Your Computer (192.168.1.100:54321)                                │
│  Dest: 54.254.243.70:5001                                                   │
│  Protocol: TCP                                                               │
│  Payload: GET /health HTTP/1.1                                              │
│     ↓                                                                        │
│  🌐 Internet Routing                                                         │
│     ↓                                                                        │
│  🌍 AWS Internet Gateway                                                     │
│     ↓                                                                        │
│  🛡️ Security Group Check                                                     │
│  ✅ Port 5001 allowed from 0.0.0.0/0                                       │
│     ↓                                                                        │
│  🖥️ EC2 Instance (10.0.1.100)                                              │
│     ↓                                                                        │
│  🐳 Docker Port Forward (8080:5000)                                         │
│     ↓                                                                        │
│  🎯 User Service Container (172.17.0.3:5001)                                │
│     ↓                                                                        │
│  📦 Response Packet:                                                         │
│  Source: 54.254.243.70:5001                                                 │
│  Dest: Your Computer (192.168.1.100:54321)                                 │
│  Payload: {"database":"connected","service":"user-service","status":"healthy"}│
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ **4. Security Architecture**

### **Security Groups (Firewall Rules)**

**EC2 Security Group Configuration**:
```hcl
resource "aws_security_group" "ec2" {
  # SSH Access (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend Web Access (Port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Microservices API Access
  ingress {
    from_port   = 5001  # User Service
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Traffic (All protocols)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### **Security Best Practices**

**Current Security**:
```
✅ SSH (Port 22): Key-based authentication
✅ HTTP (Port 8080): Public access
✅ API (Port 5001-5003): Public access
⚠️ MySQL (Port 3306): Public access (Security Risk)
```

**Recommended Improvements**:
```
🔄 MySQL: Restrict to internal network only
🔄 API: Add authentication/authorization
🔄 Frontend: Add HTTPS/SSL
🔄 SSH: Restrict to specific IP ranges
```

### **Network ACLs (Optional)**

**Network ACLs provide additional layer of security**:
```hcl
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id

  # Inbound rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Outbound rules
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
}
```

---

## 🐳 **5. Docker Networking**

### **Docker Network Types**

**1. Bridge Network (Default)**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Bridge Network                       │
│                       172.17.0.0/16                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Frontend  │  │User Service │  │    MySQL    │          │
│  │172.17.0.2   │  │172.17.0.3   │  │172.17.0.4   │          │
│  │Port: 5000   │  │Port: 5001   │  │Port: 3306   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

**2. Host Network (Direct)**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Host Network                               │
│                       10.0.1.100                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Frontend  │  │User Service │  │    MySQL    │          │
│  │Port: 8080   │  │Port: 5001   │  │Port: 3306   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### **Our Docker Compose Network Configuration**

```yaml
# docker-compose.yml
services:
  frontend:
    ports:
      - "8080:5000"  # Host:Container port mapping
    environment:
      - USER_SERVICE_URL=http://user-service:5001  # Docker DNS resolution

  user-service:
    ports:
      - "5001:5001"
    environment:
      - MYSQL_HOST=mysql  # Docker DNS resolution

  mysql:
    ports:
      - "3306:3306"
```

### **Docker Network Commands**

```bash
# List Docker networks
docker network ls

# Inspect network details
docker network inspect app_default

# Check container IPs
docker inspect user-service | grep IPAddress
docker inspect frontend | grep IPAddress
docker inspect mysql | grep IPAddress

# Test inter-container communication
docker exec frontend ping user-service
docker exec user-service ping mysql
```

---

## 🔧 **6. Troubleshooting Guide**

### **A. Network Connectivity Issues**

**1. Test Basic Connectivity**
```bash
# Test ping
ping 54.254.243.70

# Test specific ports
nc -zv 54.254.243.70 8080  # Frontend
nc -zv 54.254.243.70 5001  # User Service
nc -zv 54.254.243.70 3306  # MySQL

# Test HTTP endpoints
curl -v http://54.254.243.70:8080/
curl -v http://54.254.243.70:5001/health
```

**2. SSH Connection Issues**
```bash
# Test SSH connectivity
ssh -i ~/.ssh/gitops-key -o ConnectTimeout=10 ec2-user@54.254.243.70

# Check SSH key permissions
ls -la ~/.ssh/gitops-key
chmod 600 ~/.ssh/gitops-key

# Verify SSH key in AWS
aws ec2 describe-key-pairs --key-names gitops-key
```

**3. Security Group Issues**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxx

# Verify instance security groups
aws ec2 describe-instances --instance-ids i-xxx --query 'Reservations[0].Instances[0].SecurityGroups'
```

### **B. Docker Network Issues**

**1. Container Communication**
```bash
# SSH into EC2 instance
ssh -i ~/.ssh/gitops-key ec2-user@54.254.243.70

# Check Docker containers
docker ps
docker logs user-service
docker logs frontend

# Test inter-container communication
docker exec user-service curl -f http://mysql:3306
docker exec frontend curl -f http://user-service:5001/health
```

**2. Port Mapping Issues**
```bash
# Check port mappings
docker port user-service
docker port frontend
docker port mysql

# Check host port usage
netstat -tulpn | grep :5001
netstat -tulpn | grep :8080
```

### **C. DNS Resolution Issues**

**1. Docker DNS**
```bash
# Test Docker DNS resolution
docker exec user-service nslookup mysql
docker exec frontend nslookup user-service

# Check Docker network DNS
docker network inspect app_default | grep -A 10 "DNS"
```

**2. External DNS**
```bash
# Test external DNS resolution
nslookup 54.254.243.70
dig 54.254.243.70
```

---

## ⚡ **7. Performance Optimization**

### **Current Performance Metrics**

**Latency Breakdown**:
```
1. Internet → AWS: ~50ms
2. IGW → Security Group: ~1ms
3. Security Group → EC2: ~1ms
4. EC2 → Docker: ~1ms
5. Docker → Container: ~1ms
6. Container Processing: ~10-100ms
7. Total Round Trip: ~60-150ms
```

**Throughput**:
- **t3.micro**: Up to 5 Gbps burst
- **Docker Network**: ~10 Gbps internal
- **Security Group**: No throughput limits

### **Performance Optimization Strategies**

**1. Load Balancer Implementation**
```
Internet → ALB → EC2 Instances
Benefits:
- Health checks and failover
- SSL termination
- Path-based routing
- Sticky sessions
```

**2. Auto Scaling**
```
Auto Scaling Group:
- Scale based on CPU/memory usage
- Multiple availability zones
- Health check integration
```

**3. CDN Integration**
```
CloudFront CDN:
- Global content distribution
- Reduced latency
- DDoS protection
```

---

## 📊 **8. Monitoring & Observability**

### **Network Monitoring Tools**

**1. AWS CloudWatch**
```bash
# Monitor network metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name NetworkIn \
  --dimensions Name=InstanceId,Value=i-xxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

**2. Docker Network Monitoring**
```bash
# Monitor Docker network usage
docker stats

# Check network interfaces
docker network inspect app_default

# Monitor container network
docker exec user-service netstat -i
```

**3. Application-Level Monitoring**
```bash
# Health check endpoints
curl http://54.254.243.70:5001/health
curl http://54.254.243.70:8080/

# Log monitoring
docker logs -f user-service
docker logs -f frontend
```

### **Network Observability**

**1. Traffic Analysis**
```bash
# Monitor network traffic
tcpdump -i any port 5001
tcpdump -i any port 8080

# Analyze packet flow
tcpdump -i any -w capture.pcap
```

**2. Connection Tracking**
```bash
# Check active connections
netstat -tulpn
ss -tulpn

# Monitor connection states
cat /proc/net/tcp
```

---

## 🎯 **Summary**

Our network architecture provides:

✅ **Clear Traffic Flow**: Internet → IGW → Security Group → EC2 → Docker → Container  
✅ **Proper Port Mapping**: Host ports mapped to container ports  
✅ **Service Discovery**: Docker DNS for inter-service communication  
✅ **Security Groups**: Firewall rules for access control  
✅ **Scalable Design**: Easy to add load balancers and auto-scaling  
✅ **Monitoring Ready**: Built-in observability and troubleshooting tools  

### **Key Takeaways**

1. **VPC provides network isolation and control**
2. **Security Groups act as stateful firewalls**
3. **Docker networking enables service discovery**
4. **Proper monitoring is essential for troubleshooting**
5. **Performance optimization requires multiple layers**

### **Next Steps**

1. **Implement Load Balancer** for better scalability
2. **Add SSL/TLS** for secure communication
3. **Restrict MySQL access** to internal network only
4. **Implement proper monitoring** with CloudWatch
5. **Add network ACLs** for additional security layers

This network architecture is **production-ready** and can scale as your application grows. The key is understanding the traffic flow and implementing proper security measures at each layer.

---

## 📚 **Additional Resources**

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Docker Networking](https://docs.docker.com/network/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Security Groups Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) 