#!/bin/bash

# ArgoCD Monitoring Script
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

# Monitor ArgoCD applications
monitor_applications() {
    print_header "ArgoCD Applications Status"
    
    local apps=($(kubectl get applications -n argocd -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo ""))
    
    if [ ${#apps[@]} -eq 0 ]; then
        print_error "No ArgoCD applications found"
        return 1
    fi
    
    printf "%-20s %-15s %-15s %-10s\n" "APPLICATION" "SYNC STATUS" "HEALTH STATUS" "REVISION"
    echo "============================================================================"
    
    for app in "${apps[@]}"; do
        SYNC_STATUS=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        HEALTH_STATUS=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        REVISION=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.sync.revision}' 2>/dev/null | cut -c1-8 || echo "Unknown")
        
        # Color coding
        case $SYNC_STATUS in
            "Synced") SYNC_COLOR=$GREEN ;;
            "OutOfSync") SYNC_COLOR=$YELLOW ;;
            *) SYNC_COLOR=$RED ;;
        esac
        
        case $HEALTH_STATUS in
            "Healthy") HEALTH_COLOR=$GREEN ;;
            "Progressing") HEALTH_COLOR=$YELLOW ;;
            *) HEALTH_COLOR=$RED ;;
        esac
        
        printf "%-20s ${SYNC_COLOR}%-15s${NC} ${HEALTH_COLOR}%-15s${NC} %-10s\n" "$app" "$SYNC_STATUS" "$HEALTH_STATUS" "$REVISION"
    done
}

# Monitor resource status
monitor_resources() {
    print_header "Kubernetes Resources Status"
    
    echo "Pods Status:"
    kubectl get pods --all-namespaces | grep -E "(user-service|product-service|order-service|frontend|argocd)"
    
    echo ""
    echo "Services Status:"
    kubectl get services --all-namespaces | grep -E "(user-service|product-service|order-service|frontend|argocd)"
    
    echo ""
    echo "Ingresses Status:"
    kubectl get ingresses --all-namespaces
}

# Monitor sync waves
monitor_sync_waves() {
    print_header "ArgoCD Sync Waves"
    
    # Get all applications and their sync waves
    local apps=($(kubectl get applications -n argocd -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo ""))
    
    for app in "${apps[@]}"; do
        echo "Application: $app"
        SYNC_WAVE=$(kubectl get application "$app" -n argocd -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/sync-wave}' 2>/dev/null || echo "0")
        OPERATION_STATE=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "N/A")
        
        echo "  Sync Wave: $SYNC_WAVE"
        echo "  Operation State: $OPERATION_STATE"
        echo ""
    done
}

# Watch applications in real-time
watch_applications() {
    print_header "Watching ArgoCD Applications (Press Ctrl+C to stop)"
    
    while true; do
        clear
        monitor_applications
        echo ""
        monitor_resources
        sleep 5
    done
}

# Get ArgoCD events
get_argocd_events() {
    print_header "ArgoCD Events"
    
    kubectl get events -n argocd --sort-by='.lastTimestamp' | tail -20
}

# Get application logs
get_application_logs() {
    local app_name=$1
    
    if [ -z "$app_name" ]; then
        print_error "Please specify application name"
        return 1
    fi
    
    print_header "Logs for $app_name"
    
    # Get ArgoCD application logs
    argocd app logs "$app_name" --tail 50 2>/dev/null || {
        print_warning "ArgoCD CLI not configured, showing kubectl logs instead"
        
        # Get pod logs from the application namespace
        local pods=($(kubectl get pods -n "$app_name" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo ""))
        
        for pod in "${pods[@]}"; do
            echo "Pod: $pod"
            kubectl logs "$pod" -n "$app_name" --tail=20
            echo ""
        done
    }
}

# Sync specific application
sync_application() {
    local app_name=$1
    
    if [ -z "$app_name" ]; then
        print_error "Please specify application name"
        return 1
    fi
    
    print_status "Syncing application: $app_name"
    
    # Try ArgoCD CLI first
    if command -v argocd >/dev/null 2>&1; then
        argocd app sync "$app_name" || {
            print_warning "ArgoCD CLI sync failed, trying kubectl patch"
            kubectl patch application "$app_name" -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"syncStrategy":{"apply":{"force":true}}}}}'
        }
    else
        print_warning "ArgoCD CLI not found, using kubectl patch"
        kubectl patch application "$app_name" -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"syncStrategy":{"apply":{"force":true}}}}}'
    fi
}

# Main function
main() {
    local action=${1:-status}
    local app_name=$2
    
    case $action in
        "status")
            monitor_applications
            echo ""
            monitor_resources
            ;;
        "watch")
            watch_applications
            ;;
        "waves")
            monitor_sync_waves
            ;;
        "events")
            get_argocd_events
            ;;
        "logs")
            get_application_logs "$app_name"
            ;;
        "sync")
            sync_application "$app_name"
            ;;
        "sync-all")
            local apps=($(kubectl get applications -n argocd -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo ""))
            for app in "${apps[@]}"; do
                sync_application "$app"
            done
            ;;
        *)
            echo "Usage: $0 [action] [app_name]"
            echo "  Actions:"
            echo "    status     - Show applications status (default)"
            echo "    watch      - Watch applications in real-time"
            echo "    waves      - Show sync waves"
            echo "    events     - Show ArgoCD events"
            echo "    logs       - Show application logs (requires app_name)"
            echo "    sync       - Sync specific application (requires app_name)"
            echo "    sync-all   - Sync all applications"
            exit 1
            ;;
    esac
}

main "$@"
