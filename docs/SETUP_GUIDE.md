# 🚀 **GitOps Setup Guide**

This guide will help you set up the complete GitOps infrastructure with EKS, ArgoCD, and automated CI/CD.

## 📋 **Prerequisites**

### **1. Required Tools**
```bash
# Install required tools
brew install terraform awscli kubectl helm argocd gh

# Or install individually:
# Terraform: https://www.terraform.io/downloads
# AWS CLI: https://aws.amazon.com/cli/
# kubectl: https://kubernetes.io/docs/tasks/tools/
# Helm: https://helm.sh/docs/intro/install/
# ArgoCD CLI: https://argo-cd.readthedocs.io/en/stable/cli_installation/
# GitHub CLI: https://cli.github.com/
```

### **2. AWS Account**
- AWS account with appropriate permissions
- IAM user with programmatic access
- Access to create EKS, ECR, S3, DynamoDB resources

### **3. GitHub Repository**
- Repository with admin access
- GitHub CLI authenticated (`gh auth login`)

## 🔐 **Step 1: GitHub Secrets Setup**

You already have some secrets configured. Let's verify and add any missing ones:

### **Existing Secrets (✅ Already Configured)**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

### **Verify Secrets**
```bash
# Check existing secrets
gh secret list
```

### **Add Missing Secrets (if any)**
```bash
# Add AWS credentials (if missing)
echo "YOUR_AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID
echo "YOUR_AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY

# Add Docker Hub credentials (if missing)
echo "YOUR_DOCKERHUB_USERNAME" | gh secret set DOCKERHUB_USERNAME
echo "YOUR_DOCKERHUB_TOKEN" | gh secret set DOCKERHUB_TOKEN
```

## 🏗️ **Step 2: Automated Setup**

### **Option A: Automated Setup (Recommended)**
```bash
# Run the automated setup script
./scripts/setup-gitops.sh staging

# This will:
# 1. Check requirements
# 2. Setup GitHub secrets
# 3. Create AWS backend resources
# 4. Setup Git branches
# 5. Deploy infrastructure
# 6. Install ArgoCD
# 7. Apply App-of-Apps
```

### **Option B: Manual Setup**
If you prefer to run steps manually:

#### **2.1 Setup AWS Backend**
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://gitops-learning-terraform-state-1753768527 --region ap-southeast-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock-new \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-1
```

#### **2.2 Setup Git Branches**
```bash
# Create staging branch
git checkout -b staging
git push -u origin staging

# Create production branch
git checkout -b production
git push -u origin production

# Switch back to main
git checkout main
```

#### **2.3 Deploy Infrastructure**
```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init \
  -backend-config="bucket=gitops-learning-terraform-state-1753768527" \
  -backend-config="key=staging/terraform.tfstate" \
  -backend-config="region=ap-southeast-1" \
  -backend-config="dynamodb_table=terraform-state-lock-new" \
  -backend-config="encrypt=true"

# Plan and apply
terraform plan -var-file="environments/staging.tfvars" -out=staging.plan
terraform apply staging.plan

cd ..
```

#### **2.4 Install ArgoCD**
```bash
# Configure kubectl
aws eks update-kubeconfig --region ap-southeast-1 --name staging-cluster

# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm upgrade --install argocd argo/argocd \
  --namespace argocd \
  --create-namespace \
  --values argocd/values.yaml \
  --set server.ingress.hosts[0]=argocd.staging.example.com \
  --wait

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"
```

#### **2.5 Apply App-of-Apps**
```bash
# Apply the App-of-Apps configuration
kubectl apply -f argocd/app-of-apps.yaml
```

## 🚀 **Step 3: Deploy Applications**

### **3.1 Trigger Deployment**
```bash
# Switch to staging branch
git checkout staging

# Make a change to trigger deployment
echo "# Updated for deployment" >> README.md
git add .
git commit -m "Trigger GitOps deployment"
git push origin staging
```

### **3.2 Monitor Deployment**
1. **GitHub Actions**: Check the Actions tab in your repository
2. **ArgoCD UI**: Access ArgoCD at `https://argocd.staging.example.com`
   - Username: `admin`
   - Password: (from the installation output)

### **3.3 Verify Deployment**
```bash
# Check application status
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
kubectl get ingress --all-namespaces

# Test endpoints
kubectl get ingress -n frontend frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 🔧 **Step 4: Configuration**

### **4.1 Update ArgoCD Server URL**
If you have a custom domain, update the ArgoCD configuration:

```bash
# Update ArgoCD ingress
kubectl patch ingress argocd-server -n argocd --type='json' -p='[{"op": "replace", "path": "/spec/rules/0/host", "value": "argocd.your-domain.com"}]'
```

### **4.2 Update Application URLs**
Update the application manifests with your domain:

```yaml
# In k8s-manifests/apps/frontend/base/ingress.yaml
spec:
  rules:
  - host: your-domain.com
```

### **4.3 Configure DNS**
Point your domain to the ALB endpoint:
```bash
# Get ALB endpoint
kubectl get ingress -n frontend frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 🛠️ **Step 5: Operations**

### **5.1 Deploy to Production**
```bash
# Switch to production branch
git checkout production

# Make changes
git add .
git commit -m "Deploy to production"
git push origin production
```

### **5.2 Rollback**
```bash
# Git rollback
git revert HEAD
git push origin staging

# ArgoCD rollback
argocd app rollback user-service
```

### **5.3 Scaling**
```bash
# Horizontal scaling
kubectl scale deployment user-service --replicas=3

# Vertical scaling (via Terraform)
terraform apply -var="node_group_desired_capacity=3"
```

## 🔍 **Step 6: Monitoring**

### **6.1 Access ArgoCD**
- **URL**: `https://argocd.staging.example.com`
- **Username**: `admin`
- **Password**: (from installation output)

### **6.2 Check Application Status**
```bash
# List ArgoCD applications
argocd app list

# Check application sync status
argocd app sync user-service

# View application logs
argocd app logs user-service
```

### **6.3 Kubernetes Resources**
```bash
# Check pods
kubectl get pods --all-namespaces

# Check services
kubectl get services --all-namespaces

# Check ingress
kubectl get ingress --all-namespaces

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. ArgoCD Not Accessible**
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ArgoCD service
kubectl get svc -n argocd

# Check ingress
kubectl get ingress -n argocd
```

#### **2. Applications Not Syncing**
```bash
# Check ArgoCD applications
argocd app list

# Sync applications manually
argocd app sync app-of-apps

# Check application logs
argocd app logs app-of-apps
```

#### **3. Pod Startup Issues**
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Check resource limits
kubectl top pods -n <namespace>
```

#### **4. Network Issues**
```bash
# Check services
kubectl get svc -n <namespace>

# Check endpoints
kubectl get endpoints -n <namespace>

# Test connectivity
kubectl run test-curl --image=curlimages/curl -i --rm --restart=Never -- curl http://service-name:port
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

## 📚 **Next Steps**

1. **Customize Applications**: Update the application manifests in `k8s-manifests/apps/`
2. **Add Monitoring**: Install Prometheus and Grafana
3. **Setup Alerts**: Configure alerting for your applications
4. **Security**: Implement network policies and pod security standards
5. **Backup**: Setup backup strategies for your applications

## 🎉 **Success!**

Your GitOps infrastructure is now ready! You can:

- **Deploy applications** by pushing to staging/production branches
- **Monitor deployments** in ArgoCD UI
- **Scale applications** through GitOps
- **Rollback changes** automatically

For more information, see:
- [Architecture Documentation](ARCHITECTURE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Network Architecture](network-architecture.md) 