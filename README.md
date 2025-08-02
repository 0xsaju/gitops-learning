# 🚀 **GitOps Learning - Production Infrastructure**

A complete **production-grade GitOps infrastructure** built with EKS, ArgoCD, and automated CI/CD pipelines. This project demonstrates modern DevOps practices with zero-touch deployments and comprehensive monitoring.

## 🎯 **Features**

✅ **Production-Ready Infrastructure**: EKS cluster with proper networking  
✅ **GitOps Deployment**: ArgoCD with App-of-Apps pattern  
✅ **Secure CI/CD**: OIDC-based GitHub Actions (no static keys)  
✅ **Cost Optimized**: AWS Free Tier compatible  
✅ **Monitoring**: Prometheus, Grafana, CloudWatch  
✅ **Secrets Management**: External Secrets Operator  
✅ **Multi-Environment**: Staging and Production support  

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitOps Infrastructure                       │
├─────────────────────────────────────────────────────────────────┤
│  GitHub Actions (OIDC) → AWS EKS → ArgoCD → Applications     │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Frontend  │  │User Service │  │Product Svc  │          │
│  │   (React)   │  │  (Flask)    │  │  (Flask)    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│         │                │                │                   │
│         └────────────────┼────────────────┘                   │
│                          │                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │Order Service│  │   MySQL     │  │   Redis     │          │
│  │  (Flask)    │  │  Database   │  │   Cache     │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **Prerequisites**

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** with admin access
3. **Local Tools**:
   ```bash
   # Install required tools
   brew install terraform awscli kubectl helm argocd
   ```

### **1. Clone and Setup**

```bash
# Clone the repository
git clone https://github.com/your-username/gitops-learning.git
cd gitops-learning

# Create staging branch
git checkout -b staging
```

### **2. Configure AWS**

```bash
# Configure AWS credentials
aws configure

# Create S3 bucket for Terraform state (if not exists)
aws s3 mb s3://gitops-learning-terraform-state-1753768527 --region ap-southeast-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock-new \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-1
```

### **3. Setup GitHub Secrets**

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

```
AWS_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-role
```

### **4. Bootstrap Infrastructure**

```bash
# Run the bootstrap script
./scripts/bootstrap.sh staging

# This will:
# - Deploy EKS cluster
# - Install ArgoCD
# - Setup monitoring
# - Apply App-of-Apps
```

### **5. Deploy Applications**

```bash
# Push to staging branch to trigger deployment
git add .
git commit -m "Initial GitOps setup"
git push origin staging
```

## 📁 **Project Structure**

```
gitops-learning/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # EKS cluster configuration
│   ├── variables.tf             # Variable definitions
│   ├── backend.tf               # Remote state configuration
│   └── environments/            # Environment-specific configs
│       ├── staging.tfvars
│       └── production.tfvars
├── k8s-manifests/              # Kubernetes manifests
│   ├── kustomization.yaml      # Main kustomization
│   ├── argocd-applications/    # ArgoCD application configs
│   └── apps/                   # Application manifests
│       ├── user-service/
│       ├── product-service/
│       ├── order-service/
│       └── frontend/
├── argocd/                     # ArgoCD configuration
│   ├── values.yaml             # Helm values
│   └── app-of-apps.yaml       # App-of-Apps pattern
├── .github/workflows/          # CI/CD pipelines
│   └── gitops-deploy.yml      # Main deployment workflow
├── scripts/                    # Automation scripts
│   ├── bootstrap.sh           # Infrastructure setup
│   └── cleanup.sh             # Infrastructure cleanup
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md        # Architecture details
│   └── TROUBLESHOOTING.md     # Troubleshooting guide
└── README.md                   # This file
```

## 🔧 **Configuration**

### **Environment Variables**

```bash
# Staging Environment
environment=staging
aws_region=ap-southeast-1
kubernetes_version=1.28
node_group_instance_types=["t3.micro"]

# Production Environment
environment=production
aws_region=ap-southeast-1
kubernetes_version=1.28
node_group_instance_types=["t3.small", "t3.medium"]
```

### **GitHub Actions Secrets**

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ROLE_ARN` | IAM role for GitHub Actions | `arn:aws:iam::123456789012:role/github-actions-role` |

## 🚀 **Deployment Process**

### **1. Code Push**
```bash
git checkout staging
# Make changes
git add .
git commit -m "Update application"
git push origin staging
```

### **2. Automated Pipeline**
1. **Build & Push**: Docker images to ECR
2. **Infrastructure**: Terraform applies changes
3. **ArgoCD**: Installs/updates applications
4. **Health Check**: Verifies deployment

### **3. Verification**
- **ArgoCD UI**: Check application status
- **Kubernetes**: Verify pod health
- **Endpoints**: Test application URLs

## 🔐 **Security Features**

### **1. Authentication**
- **OIDC**: GitHub Actions to AWS (no static keys)
- **IRSA**: Pod identity for AWS services
- **RBAC**: Kubernetes role-based access

### **2. Network Security**
- **Private Subnets**: Application pods
- **Security Groups**: Minimal required access
- **Network Policies**: Pod-to-pod communication

### **3. Secrets Management**
- **External Secrets**: Sync from AWS Secrets Manager
- **Encrypted Storage**: EBS volumes encrypted
- **Secure Communication**: TLS everywhere

## 📊 **Monitoring & Observability**

### **1. Metrics**
- **Prometheus**: Cluster and application metrics
- **Grafana**: Visualization dashboards
- **CloudWatch**: AWS service metrics

### **2. Logging**
- **Fluent Bit**: Log collection
- **CloudWatch Logs**: Centralized logging
- **Application Logs**: Structured JSON logging

### **3. Alerting**
- **Prometheus Alertmanager**: Kubernetes alerts
- **CloudWatch Alarms**: AWS service alerts
- **Slack/PagerDuty**: Incident notifications

## 🛠️ **Operations**

### **1. Scaling**
```bash
# Horizontal scaling
kubectl scale deployment user-service --replicas=3

# Vertical scaling (via Terraform)
terraform apply -var="node_group_desired_capacity=3"
```

### **2. Rollback**
```bash
# Git rollback
git revert HEAD
git push origin staging

# ArgoCD rollback
argocd app rollback user-service
```

### **3. Troubleshooting**
```bash
# Check pod status
kubectl get pods --all-namespaces

# Check ArgoCD applications
argocd app list

# Check logs
kubectl logs -f deployment/user-service
```

## 💰 **Cost Optimization**

### **1. Resource Sizing**
- **Staging**: t3.micro nodes (Free Tier)
- **Production**: t3.small/medium nodes
- **Auto Scaling**: Based on CPU/memory

### **2. Storage**
- **EBS**: gp3 volumes for better performance
- **ECR Lifecycle**: Keep last 5 images
- **S3**: Intelligent tiering for logs

### **3. Network**
- **Single AZ**: For staging (cost)
- **Multi-AZ**: For production (availability)
- **NAT Gateway**: Single instance for staging

## 🔧 **Development Workflow**

### **1. Local Development**
```bash
# Start local environment
docker-compose up -d

# Run tests
pytest tests/

# Build images
docker build -t user-service:latest user-service/
```

### **2. Testing**
```bash
# Unit tests
pytest tests/unit/

# Integration tests
pytest tests/integration/

# E2E tests
pytest tests/e2e/
```

### **3. Deployment**
```bash
# Staging deployment
git push origin staging

# Production deployment
git push origin production
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Pod Startup Failures**
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. **ArgoCD Sync Issues**
   ```bash
   argocd app sync <app-name>
   argocd app logs <app-name>
   ```

3. **Network Connectivity**
   ```bash
   kubectl get endpoints
   kubectl get services
   ```

### **Debug Commands**
```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes

# Check ArgoCD status
argocd version
argocd app list

# Check AWS resources
aws eks describe-cluster --name staging-cluster
```

## 📚 **Documentation**

- **[Architecture Guide](docs/ARCHITECTURE.md)**: Detailed architecture documentation
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)**: Common issues and solutions
- **[Network Architecture](network-architecture.md)**: Network flow and security

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- [ArgoCD](https://argoproj.github.io/cd/) for GitOps
- [Terraform AWS Modules](https://github.com/terraform-aws-modules) for infrastructure
- [AWS EKS](https://aws.amazon.com/eks/) for managed Kubernetes
- [GitHub Actions](https://github.com/features/actions) for CI/CD

---

## 🎉 **Success!**

Your GitOps infrastructure is now ready! 

**Next Steps:**
1. Access ArgoCD: `https://argocd.staging.example.com`
2. Monitor applications in the ArgoCD UI
3. Push changes to trigger deployments
4. Set up monitoring dashboards

**Support:**
- 📧 Email: support@example.com
- 💬 Slack: #gitops-learning
- 📖 Docs: [Documentation](docs/)
