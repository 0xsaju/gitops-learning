# 🧪 **GitOps Pipeline Testing Guide**

This guide will help you test the complete GitOps pipeline from code push to ArgoCD monitoring.

## 🚀 **Quick Start Testing**

### **1. Run Complete Pipeline Test**
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run comprehensive test
./scripts/test-pipeline.sh staging all

# This will test:
# - Prerequisites
# - Infrastructure
# - ArgoCD applications
# - Application deployments
# - Endpoints
# - ArgoCD access
# - Application functionality
```

### **2. Monitor ArgoCD Applications**
```bash
# Check application status
./scripts/monitor-argocd.sh status

# Watch applications in real-time
./scripts/monitor-argocd.sh watch

# Check sync waves
./scripts/monitor-argocd.sh waves
```

## 📋 **Step-by-Step Testing**

### **Step 1: Test Prerequisites**
```bash
./scripts/test-pipeline.sh staging prereq
```

**Expected Output:**
```
✅ Prerequisites check
```

### **Step 2: Test Infrastructure**
```bash
./scripts/test-pipeline.sh staging infra
```

**Expected Output:**
```
✅ EKS cluster connectivity
✅ Cluster nodes (2 nodes found)
✅ ArgoCD installation
✅ External Secrets Operator
```

### **Step 3: Test ArgoCD Applications**
```bash
./scripts/test-pipeline.sh staging argocd
```

**Expected Output:**
```
✅ App-of-Apps application
✅ user-service application exists
✅ product-service application exists
✅ order-service application exists
✅ frontend application exists
```

### **Step 4: Test Application Deployments**
```bash
./scripts/test-pipeline.sh staging deploy
```

**Expected Output:**
```
✅ user-service namespace exists
✅ user-service deployment ready (1/1)
✅ product-service namespace exists
✅ product-service deployment ready (1/1)
✅ order-service namespace exists
✅ order-service deployment ready (1/1)
✅ frontend namespace exists
✅ frontend deployment ready (1/1)
```

### **Step 5: Test Application Endpoints**
```bash
./scripts/test-pipeline.sh staging endpoints
```

**Expected Output:**
```
✅ user-service health endpoint
✅ product-service health endpoint
✅ order-service health endpoint
✅ Frontend external endpoint (http://your-alb-endpoint.com)
```

### **Step 6: Test ArgoCD Access**
```bash
./scripts/test-pipeline.sh staging access
```

**Expected Output:**
```
✅ ArgoCD web interface (https://your-argocd-endpoint.com)
✅ ArgoCD admin password: CgxyP-oE0nUto3b
```

## 🔄 **Testing Complete Workflow**

### **Test Code Push to Deployment**
```bash
# 1. Make a test change
echo "# Test change - $(date)" >> README.md
git add README.md
git commit -m "Test: GitOps pipeline test"

# 2. Push to staging
git push origin staging

# 3. Monitor the pipeline
./scripts/test-pipeline.sh staging workflow
```

### **Monitor GitHub Actions**
1. Go to your repository on GitHub
2. Click on "Actions" tab
3. Watch the "GitOps CI/CD Pipeline" workflow
4. Verify all steps complete successfully

### **Monitor ArgoCD**
```bash
# Watch applications sync
./scripts/monitor-argocd.sh watch

# Check specific application
./scripts/monitor-argocd.sh logs user-service

# Force sync if needed
./scripts/monitor-argocd.sh sync user-service
```

## 🎯 **Specific Test Cases**

### **Test 1: User Registration**
```bash
# Get frontend endpoint
ALB_ENDPOINT=$(kubectl get ingress frontend-ingress -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test user registration
curl -X POST -d "username=testuser&first_name=Test&last_name=User&email=test@example.com&password=testpass123" \
  http://$ALB_ENDPOINT/register

# Expected: Redirect to login page or success message
```

### **Test 2: Service Health Checks**
```bash
# Test user service
kubectl run test-curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl -f http://user-service.user-service.svc.cluster.local:5001/health

# Expected output:
# {"status":"healthy","service":"user-service","database":"connected"}
```

### **Test 3: Database Connectivity**
```bash
# Check if services can connect to database
kubectl logs -n user-service deployment/user-service | grep -i database

# Expected: No connection errors
```

### **Test 4: ArgoCD Application Sync**
```bash
# Check sync status
kubectl get applications -n argocd

# Expected: All applications should show "Synced" status
```

## 🐛 **Troubleshooting Tests**

### **Common Issues and Solutions**

#### **1. Applications Not Syncing**
```bash
# Check ArgoCD application status
kubectl describe application user-service -n argocd

# Check sync waves
./scripts/monitor-argocd.sh waves

# Force sync all applications
./scripts/monitor-argocd.sh sync-all
```

#### **2. Pods Not Starting**
```bash
# Check pod status
kubectl get pods --all-namespaces | grep -v Running

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check resource limits
kubectl top pods --all-namespaces
```

#### **3. Service Connectivity Issues**
```bash
# Test service DNS resolution
kubectl run test-dns --image=busybox -i --rm --restart=Never -- \
  nslookup user-service.user-service.svc.cluster.local

# Test service connectivity
kubectl run test-curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl -v http://user-service.user-service.svc.cluster.local:5001/health
```

#### **4. External Access Issues**
```bash
# Check ingress status
kubectl get ingress --all-namespaces

# Check ALB provisioning
kubectl describe ingress frontend-ingress -n frontend

# Check security groups
aws ec2 describe-security-groups --group-ids <security-group-id>
```

## 📊 **Test Report Generation**
```bash
# Generate comprehensive test report
./scripts/test-pipeline.sh staging report
```

**Report includes:**
- Cluster information
- Node status
- ArgoCD applications
- Application deployments
- Services
- Ingresses
- Important URLs and credentials

## 🚨 **Emergency Procedures**

### **Rollback Deployment**
```bash
# Git rollback
git revert HEAD
git push origin staging

# ArgoCD rollback
./scripts/monitor-argocd.sh sync user-service
```

### **Restart All Services**
```bash
# Restart deployments
kubectl rollout restart deployment/user-service -n user-service
kubectl rollout restart deployment/product-service -n product-service
kubectl rollout restart deployment/order-service -n order-service
kubectl rollout restart deployment/frontend -n frontend
```

### **Clean Restart**
```bash
# Delete and recreate applications
kubectl delete application --all -n argocd
kubectl apply -f argocd/app-of-apps.yaml
```

## 📈 **Continuous Testing**

### **Set up Automated Testing**
Add this to your `.github/workflows/gitops-deploy.yml`:

```yaml
- name: Run Pipeline Tests
  run: |
    chmod +x scripts/test-pipeline.sh
    ./scripts/test-pipeline.sh ${{ steps.env.outputs.environment }} all
```

### **Monitor Health Continuously**
```bash
# Set up a cron job to monitor health
echo "*/5 * * * * /path/to/gitops-learning/scripts/test-pipeline.sh staging endpoints" | crontab -
```

## 🎉 **Success Criteria**

Your GitOps pipeline is working correctly when:

1. ✅ **Infrastructure Tests Pass**: EKS cluster, nodes, ArgoCD, External Secrets
2. ✅ **Application Tests Pass**: All applications deployed and running
3. ✅ **Endpoint Tests Pass**: All services responding to health checks
4. ✅ **ArgoCD Tests Pass**: All applications synced and healthy
5. ✅ **Functionality Tests Pass**: User registration, service communication
6. ✅ **Workflow Tests Pass**: Code push triggers successful deployment

## 📚 **Next Steps**

After successful testing:
1. **Set up monitoring alerts**
2. **Configure backup strategies**
3. **Implement security scanning**
4. **Add performance testing**
5. **Set up disaster recovery**

For more information, see:
- [Setup Guide](SETUP_GUIDE.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
