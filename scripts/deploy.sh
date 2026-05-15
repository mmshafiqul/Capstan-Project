#!/bin/bash

# URL Shortener Microservices Deployment Script
# This script automates the complete deployment process

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="urlshortner"
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-mmshafiqul}"
AWS_REGION="${AWS_REGION:-}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-${CLUSTER_NAME:-}}"
AWS_PROFILE="${AWS_PROFILE:-}"
TF_DIR="${TF_DIR:-terraform}"
TF_VARS_FILE="${TF_VARS_FILE:-terraform.tfvars}"
ENABLE_EBS_CSI_DRIVER="${ENABLE_EBS_CSI_DRIVER:-true}"
# By default this script also builds + pushes images to Docker Hub so the cluster can pull them.
# Set BUILD_PUSH_IMAGES=false to skip.
BUILD_PUSH_IMAGES="${BUILD_PUSH_IMAGES:-true}"
# If Terraform registry access is flaky, set TF_OFFLINE=true to avoid network calls during init.
# This requires that providers/modules were already downloaded at least once in TF_DIR.
TF_OFFLINE="${TF_OFFLINE:-false}"
TF_INIT_ARGS="${TF_INIT_ARGS:--upgrade=false}"

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗ $1${NC}"
}

debug_deployment() {
    local deployment="$1"
    local selector="$2"

    warning "Deployment ${deployment} did not become ready. Collecting diagnostics..."
    kubectl get deployment "${deployment}" -n "${NAMESPACE}" -o wide || true
    kubectl get pods -n "${NAMESPACE}" -l "${selector}" -o wide || true
    kubectl describe deployment "${deployment}" -n "${NAMESPACE}" || true
    kubectl describe pods -n "${NAMESPACE}" -l "${selector}" || true
    kubectl logs -n "${NAMESPACE}" -l "${selector}" --tail=100 --all-containers=true || true
}

wait_for_deployment() {
    local deployment="$1"
    local selector="$2"

    if ! kubectl rollout status "deployment/${deployment}" -n "${NAMESPACE}" --timeout=300s; then
        debug_deployment "${deployment}" "${selector}"
        return 1
    fi
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if required tools are installed
    command -v terraform >/dev/null 2>&1 || { error "Terraform is not installed. Please install it first."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { error "kubectl is not installed. Please install it first."; exit 1; }
    command -v helm >/dev/null 2>&1 || { error "Helm is not installed. Please install it first."; exit 1; }
    command -v aws >/dev/null 2>&1 || { error "AWS CLI is not installed. Please install it first."; exit 1; }
    command -v docker >/dev/null 2>&1 || warning "Docker not found (BUILD_PUSH_IMAGES=false is OK)."
    
    # Check AWS credentials (use profile if provided)
    if [ -n "${AWS_PROFILE}" ]; then
        aws --profile "${AWS_PROFILE}" sts get-caller-identity >/dev/null 2>&1 || { error "AWS credentials are not configured for profile '${AWS_PROFILE}'."; exit 1; }
    else
        aws sts get-caller-identity >/dev/null 2>&1 || { error "AWS credentials are not configured. Please run 'aws configure' or export AWS_* env vars."; exit 1; }
    fi
    
    success "Prerequisites check passed"
}

deploy_infrastructure() {
    log "Deploying infrastructure with Terraform..."
    
    cd "${TF_DIR}"
    
    # Initialize Terraform
    # Prefer offline-friendly init when caches already exist.
    # If you previously ran init successfully, this avoids re-downloading modules/providers.
    if [ "${TF_OFFLINE}" = "true" ]; then
        # Use already-downloaded providers/modules. Helpful on restricted networks.
        terraform init -get=false -upgrade=false -plugin-dir=.terraform/providers
    else
        terraform init ${TF_INIT_ARGS}
    fi
    
    # Plan and apply
    terraform plan -var-file="${TF_VARS_FILE}" -out=tfplan
    terraform apply tfplan
    
    # Get outputs
    CLUSTER_NAME="$(terraform output -raw cluster_name)"
    AWS_REGION="$(terraform output -raw region)"
    
    cd ..
    
    success "Infrastructure deployed successfully"
}

configure_kubectl() {
    log "Configuring kubectl..."

    if [ -z "${AWS_REGION}" ] || [ -z "${CLUSTER_NAME}" ]; then
        log "Reading AWS_REGION/CLUSTER_NAME from Terraform outputs..."
        pushd "${TF_DIR}" >/dev/null
        AWS_REGION="$(terraform output -raw region)"
        CLUSTER_NAME="$(terraform output -raw cluster_name)"
        popd >/dev/null
    fi

    if [ -n "${AWS_PROFILE}" ]; then
        aws --profile "${AWS_PROFILE}" eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"
    else
        aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"
    fi
    
    # Verify cluster access
    kubectl get nodes
    
    success "kubectl configured successfully"
}

deploy_ebs_csi() {
    if [ "${ENABLE_EBS_CSI_DRIVER}" != "true" ]; then
        log "Skipping EBS CSI driver install (ENABLE_EBS_CSI_DRIVER=false)"
        return 0
    fi

    log "Deploying aws-ebs-csi-driver via Helm..."

    pushd "${TF_DIR}" >/dev/null
    EBS_CSI_ROLE_ARN="$(terraform output -raw ebs_csi_role_arn 2>/dev/null || true)"
    popd >/dev/null

    if [ -z "${EBS_CSI_ROLE_ARN}" ]; then
        error "Terraform output 'ebs_csi_role_arn' is empty. Apply infrastructure first so IRSA is created."
        exit 1
    fi

    helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver >/dev/null 2>&1 || true
    helm repo update

    helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
        --namespace kube-system \
        --set controller.serviceAccount.create=true \
        --set controller.serviceAccount.name=ebs-csi-controller-sa \
        --set controller.serviceAccount.annotations."eks\\.amazonaws\\.com/role-arn"="${EBS_CSI_ROLE_ARN}"

    kubectl rollout status deployment/ebs-csi-controller -n kube-system --timeout=300s

    success "aws-ebs-csi-driver deployed successfully"
}

build_and_push_images() {
    if [ "${BUILD_PUSH_IMAGES}" != "true" ]; then
        log "Skipping docker build/push (BUILD_PUSH_IMAGES=false)"
        return 0
    fi

    log "Building and pushing images to Docker Hub as ${DOCKERHUB_USERNAME}..."

    if [ -n "${DOCKERHUB_TOKEN:-}" ]; then
        echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
    else
        log "DOCKERHUB_TOKEN not set; using interactive docker login..."
        docker login -u "${DOCKERHUB_USERNAME}"
    fi

    for svc in go-service node-service python-service; do
        log "Building ${svc}..."
        docker build -t "${DOCKERHUB_USERNAME}/${svc}:latest" "./${svc}"
        log "Pushing ${svc}..."
        docker push "${DOCKERHUB_USERNAME}/${svc}:latest"
    done

    success "Images built and pushed"
}

deploy_monitoring() {
    log "Deploying add-ons (ingress-nginx, kube-prometheus-stack, metrics-server) via Helm..."

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
    helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ >/dev/null 2>&1 || true
    helm repo update

    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set grafana.adminPassword=admin123

    kubectl wait --for=condition=Established crd/servicemonitors.monitoring.coreos.com --timeout=300s

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.replicaCount=2 \
        --set controller.service.type=LoadBalancer \
        --set controller.service.annotations."service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"=nlb \
        --set controller.metrics.enabled=true \
        --set controller.metrics.serviceMonitor.enabled=true

    helm upgrade --install metrics-server metrics-server/metrics-server \
        --namespace kube-system \
        --set-json 'args=["--kubelet-insecure-tls","--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"]'

    success "Add-ons deployed successfully"
}

deploy_applications() {
    log "Deploying applications..."
    
    TMP_K8S_DIR="$(mktemp -d)"
    cp -R k8s/*.yaml "${TMP_K8S_DIR}/"

    # Replace image placeholders without modifying the repo
    sed -i "s|your-dockerhub-username|${DOCKERHUB_USERNAME}|g" "${TMP_K8S_DIR}"/*-deployment.yaml
    
    # Create namespace
    kubectl apply -f "${TMP_K8S_DIR}/namespace.yaml"
    
    # Apply ConfigMaps and Secrets
    kubectl apply -f "${TMP_K8S_DIR}/configmaps.yaml"
    kubectl apply -f "${TMP_K8S_DIR}/secrets.yaml"
    
    # Deploy Redis first (dependency)
    kubectl apply -f "${TMP_K8S_DIR}/redis-deployment.yaml"
    log "Waiting for Redis to be ready..."
    kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=300s
    
    # Deploy services
    kubectl apply -f "${TMP_K8S_DIR}/go-service-deployment.yaml"
    kubectl apply -f "${TMP_K8S_DIR}/node-service-deployment.yaml"
    kubectl apply -f "${TMP_K8S_DIR}/python-service-deployment.yaml"
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    wait_for_deployment go-service app=go-service
    wait_for_deployment node-service app=node-service
    wait_for_deployment python-service app=python-service
    
    # Apply Ingress and HPA
    kubectl apply -f "${TMP_K8S_DIR}/ingress.yaml"
    kubectl apply -f "${TMP_K8S_DIR}/hpa.yaml"

    # Optional: scrape ingress-nginx metrics (CRD exists only if kube-prometheus-stack is installed)
    kubectl apply -f "${TMP_K8S_DIR}/monitoring-servicemonitor.yaml" >/dev/null 2>&1 || true

    rm -rf "${TMP_K8S_DIR}"
    
    success "Applications deployed successfully"
}

verify_deployment() {
    log "Verifying deployment..."
    
    # Check pod status
    log "Pod status:"
    kubectl get pods -n $NAMESPACE
    
    # Check services
    log "Services:"
    kubectl get services -n $NAMESPACE
    
    # Check HPA
    log "HPA status:"
    kubectl get hpa -n $NAMESPACE
    
    # Check Ingress
    log "Ingress status:"
    kubectl get ingress -n $NAMESPACE
    
    # Get load balancer URLs
    log "Load Balancer URLs:"
    INGRESS_LB=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    GRAFANA_LB=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)

    if [ -n "${INGRESS_LB}" ]; then
        echo "Ingress Load Balancer: http://${INGRESS_LB}"
    else
        warning "Ingress load balancer hostname is not assigned yet. Check: kubectl get svc ingress-nginx-controller -n ingress-nginx -o wide"
    fi

    if [ -n "${GRAFANA_LB}" ]; then
        echo "Grafana Dashboard: http://${GRAFANA_LB} (admin/admin123)"
    else
        warning "Grafana load balancer hostname is not assigned yet. Check: kubectl get svc prometheus-grafana -n monitoring -o wide"
    fi
    
    success "Deployment verification completed"
}

run_smoke_tests() {
    log "Running smoke tests..."
    
    # Wait for pods to be fully ready
    sleep 30
    
    # Test Python service
    PYTHON_POD=$(kubectl get pods -n $NAMESPACE -l app=python-service -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n $NAMESPACE $PYTHON_POD -- curl -f http://localhost:5000/ || { error "Python service health check failed"; return 1; }
    
    # Test Go service
    GO_POD=$(kubectl get pods -n $NAMESPACE -l app=go-service -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n $NAMESPACE $GO_POD -- curl -sf -X POST http://localhost:8000/api/shorten -H 'Content-Type: application/json' -d '{"long_url":"https://example.com"}' >/dev/null || { error "Go service smoke test failed"; return 1; }
    
    # Test Node service
    NODE_POD=$(kubectl get pods -n $NAMESPACE -l app=node-service -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n $NAMESPACE $NODE_POD -- curl -f http://localhost:3000/health || { error "Node service health check failed"; return 1; }
    
    success "Smoke tests passed"
}

cleanup() {
    log "Cleaning up temporary files..."
    # Add any cleanup logic here
    success "Cleanup completed"
}

main() {
    log "Starting URL Shortener Microservices deployment..."
    
    # Trap to cleanup on exit
    trap cleanup EXIT
    
    check_prerequisites
    deploy_infrastructure
    configure_kubectl
    deploy_ebs_csi
    build_and_push_images
    deploy_monitoring
    deploy_applications
    verify_deployment
    run_smoke_tests
    
    success "Deployment completed successfully!"
    
    log "Next steps:"
    echo "1. Get the ingress-nginx LB DNS: kubectl get svc -n ingress-nginx"
    echo "2. Access the app via: http://<AWS_LB_DNS>/"
    echo "3. Access Grafana via: kubectl get svc -n monitoring"
    echo "4. Verify metrics: kubectl top pods -n urlshortner"
}

# Handle script arguments
case "${1:-}" in
    "infra")
        check_prerequisites
        deploy_infrastructure
        ;;
    "apps")
        configure_kubectl
        deploy_ebs_csi
        deploy_applications
        ;;
    "monitoring")
        configure_kubectl
        deploy_ebs_csi
        deploy_monitoring
        ;;
    "verify")
        configure_kubectl
        verify_deployment
        ;;
    "test")
        configure_kubectl
        run_smoke_tests
        ;;
    "cleanup")
        log "Destroying infrastructure..."
        cd terraform
        terraform destroy
        ;;
    *)
        main
        ;;
esac
