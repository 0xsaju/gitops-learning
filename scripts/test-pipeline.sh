#!/bin/bash

# GitOps Pipeline Testing Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_test_result() {
    if [ $1 -eq 0 ]; then
        print_success "$2"
    else
        print_error "❌ $2"
        return 1
    fi
}

# Test prerequisites
test_prerequisites() {
    print_header "Testing Prerequisites"
    
    local failed=0
    
    # Check required tools
    command -v git >/dev/null 2>&1 || { print_error "git not found"; failed=1; }
    command -v kubectl >/dev/null 2>&1 || { print_error "kubectl not found"; failed=1; }
    command -v aws >/dev/null 2>&1 || { print_error "aws cli not found"; failed=1; }
    command -v argocd >/dev/null 2>&1 || { print_error "argocd cli not found"; failed=1; }
    command -v curl >/dev/null 2>&1 || { print_error "curl not found"; failed=1; }
    
    # Check AWS credentials
    aws sts get-caller-identity >/dev/null 2>&1 || { print_error "AWS credentials not configured"; failed=1; }
    
    # Check if we're in the right directory
    [ -f "terraform/main.tf" ] || { print_error "Not in gitops-learning directory"; failed=1; }
    
    print_test_result $failed "Prerequisites check"
    return $failed
}

# Test infrastructure
test_infrastructure() {
    local environment=${1:-staging}
    print_header "Testing Infrastructure - $environment"
    
    local failed=0
    
    # Check EKS cluster
    print_status "Testing EKS cluster connection..."
    aws eks update-kubeconfig --region ap-southeast-1 --name "${environment}-cluster" >/dev/null 2>&1 || failed=1
    kubectl cluster-info >/dev/null 2>&1 || failed=1
    print_test_result $? "EKS cluster connectivity"
    
    # Check nodes
    print_status "Testing cluster nodes..."
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    [ "$NODE_COUNT" -gt 0 ] || failed=1
    print_test_result $? "Cluster nodes ($NODE_COUNT nodes found)"
    
    # Check ArgoCD installation
    print_status "Testing ArgoCD installation..."
    kubectl get namespace argocd >/dev/null 2>&1 || failed=1
    kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers | grep -q Running || failed=1
    print_test_result $? "ArgoCD installation"
    
    # Check External Secrets
    print_status "Testing External Secrets Operator..."
    kubectl get namespace external-secrets-system >/dev/null 2>&1 || failed=1
    kubectl get pods -n external-secrets-system --no-headers | grep -q Running || failed=1
    print_test_result $? "External Secrets Operator"
    
    return $failed
}

# Test ArgoCD applications
test_argocd_applications() {
    print_header "Testing ArgoCD Applications"
    
    local failed=0
    
    # Check if app-of-apps exists
    print_status "Testing App-of-Apps..."
    kubectl get application app-of-apps -n argocd >/dev/null 2>&1 || failed=1
    print_test_result $? "App-of-Apps application"
    
    # Check individual applications
    local apps=("user-service" "product-service" "order-service" "frontend")
    for app in "${apps[@]}"; do
        print_status "Testing $app application..."
        kubectl get application "$app" -n argocd >/dev/null 2>&1 || failed=1
        print_test_result $? "$app application exists"
    done
    
    # Check application sync status
    print_status "Checking application sync status..."
    local sync_failed=0
    for app in "${apps[@]}"; do
        SYNC_STATUS=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        if [ "$SYNC_STATUS" = "Synced" ]; then
            print_success "$app: $SYNC_STATUS"
        else
            print_warning "$app: $SYNC_STATUS"
            sync_failed=1
        fi
    done
    
    return $failed
}

# Test application deployments
test_application_deployments() {
    print_header "Testing Application Deployments"
    
    local failed=0
    
    # Check namespaces
    local namespaces=("user-service" "product-service" "order-service" "frontend")
    for ns in "${namespaces[@]}"; do
        print_status "Testing $ns namespace..."
        kubectl get namespace "$ns" >/dev/null 2>&1 || failed=1
        print_test_result $? "$ns namespace exists"
    done
    
    # Check deployments
    for ns in "${namespaces[@]}"; do
        print_status "Testing $ns deployment..."
        kubectl get deployment "$ns" -n "$ns" >/dev/null 2>&1 || failed=1
        
        # Check if deployment is ready
        READY_REPLICAS=$(kubectl get deployment "$ns" -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        DESIRED_REPLICAS=$(kubectl get deployment "$ns" -n "$ns" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ] && [ "$READY_REPLICAS" -gt 0 ]; then
            print_success "$ns deployment ready ($READY_REPLICAS/$DESIRED_REPLICAS)"
        else
            print_warning "$ns deployment not ready ($READY_REPLICAS/$DESIRED_REPLICAS)"
            failed=1
        fi
    done
    
    return $failed
}

# Test application endpoints
test_application_endpoints() {
    print_header "Testing Application Endpoints"
    
    local failed=0
    
    # Test internal service endpoints
    local services=("user-service" "product-service" "order-service")
    for service in "${services[@]}"; do
        print_status "Testing $service internal endpoint..."
        
        # Test health endpoint
        kubectl run test-curl-$service --image=curlimages/curl -i --rm --restart=Never --quiet -- \
            curl -f "http://$service.$service.svc.cluster.local:5001/health" >/dev/null 2>&1 || failed=1
        print_test_result $? "$service health endpoint"
    done
    
    # Test frontend external endpoint
    print_status "Testing frontend external endpoint..."
    ALB_ENDPOINT=$(kubectl get ingress frontend-ingress -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$ALB_ENDPOINT" ]; then
        # Wait for ALB to be ready
        print_status "Waiting for ALB to be ready..."
        local retries=0
        while [ $retries -lt 30 ]; do
            if curl -f -s "http://$ALB_ENDPOINT/" >/dev/null 2>&1; then
                break
            fi
            sleep 10
            retries=$((retries + 1))
        done
        
        curl -f -s "http://$ALB_ENDPOINT/" >/dev/null 2>&1 || failed=1
        print_test_result $? "Frontend external endpoint (http://$ALB_ENDPOINT)"
    else
        print_error "Frontend ALB endpoint not found"
        failed=1
    fi
    
    return $failed
}

# Test ArgoCD access
test_argocd_access() {
    print_header "Testing ArgoCD Access"
    
    local failed=0
    
    # Get ArgoCD endpoint
    ARGOCD_ENDPOINT=$(kubectl get ingress argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$ARGOCD_ENDPOINT" ]; then
        print_status "Testing ArgoCD web interface..."
        
        # Test ArgoCD endpoint
        local retries=0
        while [ $retries -lt 30 ]; do
            if curl -f -s -k "https://$ARGOCD_ENDPOINT/" >/dev/null 2>&1; then
                break
            fi
            sleep 10
            retries=$((retries + 1))
        done
        
        curl -f -s -k "https://$ARGOCD_ENDPOINT/" >/dev/null 2>&1 || failed=1
        print_test_result $? "ArgoCD web interface (https://$ARGOCD_ENDPOINT)"
        
        # Get ArgoCD admin password
        ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")
        if [ -n "$ARGOCD_PASSWORD" ]; then
            print_success "ArgoCD admin password: $ARGOCD_PASSWORD"
        else
            print_warning "Could not retrieve ArgoCD admin password"
        fi
    else
        print_error "ArgoCD endpoint not found"
        failed=1
    fi
    
    return $failed
}

# Test complete workflow
test_workflow() {
    print_header "Testing Complete GitOps Workflow"
    
    local environment=${1:-staging}
    
    # Make a small change to trigger deployment
    print_status "Making a test change..."
    echo "# Test change - $(date)" >> README.md
    git add README.md
    git commit -m "Test: GitOps pipeline test - $(date)"
    
    print_status "Pushing to $environment branch..."
    git push origin "$environment"
    
    # Monitor GitHub Actions
    print_status "Monitoring GitHub Actions workflow..."
    print_warning "Please check GitHub Actions in your browser:"
    echo "https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
    
    # Wait for ArgoCD sync
    print_status "Waiting for ArgoCD to sync applications..."
    sleep 60
    
    # Check if applications are synced
    local apps=("user-service" "product-service" "order-service" "frontend")
    for app in "${apps[@]}"; do
        print_status "Waiting for $app to sync..."
        local retries=0
        while [ $retries -lt 30 ]; do
            SYNC_STATUS=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
            if [ "$SYNC_STATUS" = "Synced" ]; then
                print_success "$app synced successfully"
                break
            fi
            sleep 10
            retries=$((retries + 1))
        done
        
        if [ "$SYNC_STATUS" != "Synced" ]; then
            print_warning "$app sync status: $SYNC_STATUS"
        fi
    done
}

# Test application functionality
test_application_functionality() {
    print_header "Testing Application Functionality"
    
    local failed=0
    
    # Get frontend endpoint
    ALB_ENDPOINT=$(kubectl get ingress frontend-ingress -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -z "$ALB_ENDPOINT" ]; then
        print_error "Frontend endpoint not found"
        return 1
    fi
    
    print_status "Testing on endpoint: http://$ALB_ENDPOINT"
    
    # Test home page
    print_status "Testing home page..."
    curl -f -s "http://$ALB_ENDPOINT/" >/dev/null 2>&1 || failed=1
    print_test_result $? "Home page accessible"
    
    # Test user registration
    print_status "Testing user registration..."
    REGISTER_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
        -d "username=testuser$(date +%s)&first_name=Test&last_name=User&email=test$(date +%s)@example.com&password=testpass123" \
        "http://$ALB_ENDPOINT/register" 2>/dev/null || echo "000")
    
    if [[ "$REGISTER_RESPONSE" =~ 200|302 ]]; then
        print_success "User registration working"
    else
        print_warning "User registration response: $REGISTER_RESPONSE"
    fi
    
    # Test health endpoints
    print_status "Testing service health endpoints..."
    local services=("user-service" "product-service" "order-service")
    for service in "${services[@]}"; do
        kubectl run test-health-$service --image=curlimages/curl -i --rm --restart=Never --quiet -- \
            curl -f "http://$service.$service.svc.cluster.local:5001/health" 2>/dev/null || failed=1
        print_test_result $? "$service health check"
    done
    
    return $failed
}

# Generate test report
generate_report() {
    print_header "GitOps Pipeline Test Report"
    
    # Get cluster info
    print_status "Cluster Information:"
    kubectl cluster-info
    
    echo ""
    print_status "Node Status:"
    kubectl get nodes
    
    echo ""
    print_status "ArgoCD Applications:"
    kubectl get applications -n argocd
    
    echo ""
    print_status "Application Deployments:"
    kubectl get deployments --all-namespaces
    
    echo ""
    print_status "Services:"
    kubectl get services --all-namespaces
    
    echo ""
    print_status "Ingresses:"
    kubectl get ingresses --all-namespaces
    
    # Get important URLs
    ALB_ENDPOINT=$(kubectl get ingress frontend-ingress -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not found")
    ARGOCD_ENDPOINT=$(kubectl get ingress argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not found")
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "Not found")
    
    echo ""
    print_header "Important URLs and Credentials"
    echo "Frontend URL: http://$ALB_ENDPOINT"
    echo "ArgoCD URL: https://$ARGOCD_ENDPOINT"
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $ARGOCD_PASSWORD"
}

# Main function
main() {
    local environment=${1:-staging}
    local test_type=${2:-all}
    
    print_header "GitOps Pipeline Testing - Environment: $environment"
    
    case $test_type in
        "prereq")
            test_prerequisites
            ;;
        "infra")
            test_infrastructure "$environment"
            ;;
        "argocd")
            test_argocd_applications
            ;;
        "deploy")
            test_application_deployments
            ;;
        "endpoints")
            test_application_endpoints
            ;;
        "access")
            test_argocd_access
            ;;
        "workflow")
            test_workflow "$environment"
            ;;
        "functionality")
            test_application_functionality
            ;;
        "report")
            generate_report
            ;;
        "all")
            local overall_failed=0
            
            test_prerequisites || overall_failed=1
            test_infrastructure "$environment" || overall_failed=1
            test_argocd_applications || overall_failed=1
            test_application_deployments || overall_failed=1
            test_application_endpoints || overall_failed=1
            test_argocd_access || overall_failed=1
            test_application_functionality || overall_failed=1
            
            echo ""
            generate_report
            
            if [ $overall_failed -eq 0 ]; then
                print_header "🎉 All Tests Passed!"
                print_success "Your GitOps pipeline is working correctly"
            else
                print_header "⚠️  Some Tests Failed"
                print_warning "Please check the failed tests and fix issues"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [environment] [test_type]"
            echo "  environment: staging (default) or production"
            echo "  test_type: prereq, infra, argocd, deploy, endpoints, access, workflow, functionality, report, all (default)"
            exit 1
            ;;
    esac
}

# Make script executable and run
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    main "$@"
fi
