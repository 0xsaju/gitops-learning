#!/bin/bash

# Fix ArgoCD Installation Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check available charts in argo repository
check_argo_charts() {
    print_header "Checking Available ArgoCD Charts"
    
    print_status "Searching for ArgoCD charts..."
    helm search repo argo
    
    echo ""
    print_status "Available charts in argo repository:"
    helm search repo argo/argo
}

# Install ArgoCD with correct chart name
install_argocd() {
    print_header "Installing ArgoCD"
    
    # Add and update repositories
    print_status "Adding ArgoCD Helm repository..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # Check if the chart exists
    if helm search repo argo/argo-cd | grep -q "argo-cd"; then
        CHART_NAME="argo-cd"
    elif helm search repo argo/argocd | grep -q "argocd"; then
        CHART_NAME="argocd"
    else
        print_error "Could not find ArgoCD chart"
        print_status "Available charts:"
        helm search repo argo
        exit 1
    fi
    
    print_status "Using chart: argo/$CHART_NAME"
    
    # Create namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    print_status "Installing ArgoCD..."
    helm upgrade --install argocd argo/$CHART_NAME \
        --namespace argocd \
        --values argocd/values.yaml \
        --wait --timeout=600s
    
    print_status "ArgoCD installation completed"
}

# Get ArgoCD access info
get_argocd_info() {
    print_header "ArgoCD Access Information"
    
    # Wait for ArgoCD to be ready
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    
    # Get admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")
    
    if [ -n "$ARGOCD_PASSWORD" ]; then
        print_status "ArgoCD admin password: $ARGOCD_PASSWORD"
    else
        print_warning "Could not retrieve ArgoCD admin password"
        print_status "Try: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    fi
    
    # Get service information
    print_status "ArgoCD service information:"
    kubectl get svc -n argocd
    
    # Check if ingress exists
    if kubectl get ingress -n argocd argocd-server >/dev/null 2>&1; then
        ALB_ENDPOINT=$(kubectl get ingress -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending")
        print_status "ArgoCD URL: https://$ALB_ENDPOINT"
    else
        print_warning "ArgoCD ingress not found"
        print_status "You can access ArgoCD via port-forward:"
        echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
        echo "Then access: https://localhost:8080"
    fi
}

# Main function
main() {
    local action=${1:-install}
    
    case $action in
        "check")
            check_argo_charts
            ;;
        "install")
            check_argo_charts
            install_argocd
            get_argocd_info
            ;;
        "info")
            get_argocd_info
            ;;
        *)
            echo "Usage: $0 [action]"
            echo "  Actions:"
            echo "    check   - Check available ArgoCD charts"
            echo "    install - Install ArgoCD (default)"
            echo "    info    - Get ArgoCD access information"
            exit 1
            ;;
    esac
}

main "$@"
