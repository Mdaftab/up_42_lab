#!/bin/bash

# Exit on any error
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for pod readiness
wait_for_pods() {
    namespace=$1
    label=$2
    log_info "Waiting for pods with label $label in namespace $namespace to be ready..."
    kubectl wait --for=condition=ready pod -l "$label" -n "$namespace" --timeout=300s
}

# Function to wait for deployment readiness
wait_for_deployment() {
    namespace=$1
    deployment=$2
    log_info "Waiting for deployment $deployment in namespace $namespace to be ready..."
    kubectl wait --for=condition=available deployment "$deployment" -n "$namespace" --timeout=300s
}

# Function to wait for CRD to be established
wait_for_crd() {
    crd=$1
    log_info "Waiting for CRD $crd to be established..."
    kubectl wait --for=condition=established --timeout=300s crd/$crd
}

# Function to add Helm repository if it doesn't exist
add_helm_repo() {
    name=$1
    url=$2
    if ! helm repo list | grep -q "^${name}[[:space:]]"; then
        log_info "Adding Helm repository ${name}..."
        helm repo add "${name}" "${url}"
    else
        log_info "Helm repository ${name} already exists"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f "$KUBECONFIG_PATH" 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

# Check for required tools
log_info "Checking required tools..."
required_tools=("minikube" "kubectl" "helm" "terraform" "docker" "curl")
missing_tools=()
for tool in "${required_tools[@]}"; do
    if ! command_exists "$tool"; then
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    log_error "The following required tools are not installed:"
    for tool in "${missing_tools[@]}"; do
        echo "  - $tool"
    done
    exit 1
fi

# Start Minikube if not running
if ! minikube status >/dev/null 2>&1; then
    log_info "Starting Minikube..."
    minikube start --memory=4096 --cpus=2 --kubernetes-version=v1.25.0 \
        --addons=ingress,metrics-server
else
    log_info "Minikube is already running"
    # Ensure addons are enabled
    minikube addons enable ingress >/dev/null 2>&1 || true
    minikube addons enable metrics-server >/dev/null 2>&1 || true
fi

# Enable required addons
log_info "Enabling required Minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server

# Add required Helm repositories
log_info "Setting up Helm repositories..."
add_helm_repo "prometheus-community" "https://prometheus-community.github.io/helm-charts"
add_helm_repo "bitnami" "https://charts.bitnami.com/bitnami"
add_helm_repo "minio" "https://charts.min.io/"
helm repo update >/dev/null

# Create namespaces
log_info "Creating namespaces..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace s3www --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus Operator
log_info "Installing Prometheus Operator..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --wait

# Wait for Prometheus CRDs and core components
log_info "Waiting for Prometheus CRDs and components..."
wait_for_crd "servicemonitors.monitoring.coreos.com"
wait_for_crd "prometheuses.monitoring.coreos.com"

log_info "Waiting for Prometheus Operator deployment..."
wait_for_deployment "monitoring" "prometheus-kube-prometheus-operator"

log_info "Waiting for Prometheus StatefulSet..."
kubectl wait --for=condition=ready pod -l "app.kubernetes.io/name=prometheus" -n monitoring --timeout=300s

log_info "Waiting for Grafana deployment..."
wait_for_deployment "monitoring" "prometheus-grafana"

# Build and push s3www image to minikube
log_info "Building s3www image..."
eval $(minikube docker-env)
docker build -t s3www:latest ./s3www

# Change to terraform directory
cd terraform || { log_error "Terraform directory not found"; exit 1; }

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init -input=false

# Setup kubeconfig for Terraform
log_info "Setting up kubeconfig for Terraform..."
KUBECONFIG_PATH="$PWD/kubeconfig"
minikube kubectl -- config view --raw > "$KUBECONFIG_PATH"
export KUBECONFIG="$KUBECONFIG_PATH"

# Create terraform.tfvars file
log_info "Creating terraform.tfvars..."
cat > terraform.tfvars << EOF
kubeconfig_path = "${KUBECONFIG_PATH}"
environment = "development"
create_namespace = false
namespace_labels = {
  "app.kubernetes.io/managed-by" = "terraform"
  "app.kubernetes.io/part-of" = "s3www-stack"
}
namespace_annotations = {
  "app.kubernetes.io/description" = "S3WWW application namespace"
}
minio_root_user = "admin"
minio_root_password = "admin123"
enable_metrics = true
enable_servicemonitor = true
enable_ingress = true
ingress_class_name = "nginx"
ingress_host = "s3www.local"
helm_set_values = {
  "s3www.image.repository" = "s3www"
  "s3www.image.tag" = "latest"
  "minio.persistence.size" = "10Gi"
  "minio.resources.requests.memory" = "256Mi"
  "minio.resources.limits.memory" = "512Mi"
  "resources.limits.cpu" = "500m"
  "resources.limits.memory" = "512Mi"
  "resources.requests.cpu" = "250m"
  "resources.requests.memory" = "256Mi"
  "fileToServe.sourceUrl" = "https://raw.githubusercontent.com/codeium/s3www/main/README.md"
  "fileToServe.initContainer.image" = "minio/mc:latest"
  "fileToServe.initContainer.resources.limits.cpu" = "100m"
  "fileToServe.initContainer.resources.limits.memory" = "128Mi"
  "fileToServe.initContainer.resources.requests.cpu" = "50m"
  "fileToServe.initContainer.resources.requests.memory" = "64Mi"
  "metrics.port" = "9090"
}
EOF

# Apply Terraform configuration
log_info "Applying Terraform configuration..."
if ! terraform apply -auto-approve; then
    log_error "Terraform apply failed"
    exit 1
fi

# Wait for deployments
log_info "Waiting for deployments to be ready..."
kubectl rollout status deployment/minio -n s3www || log_warning "MinIO deployment not ready"
kubectl rollout status deployment/s3www -n s3www || log_warning "S3WWW deployment not ready"

# Get service URLs
log_info "Getting service URLs..."
MINIO_URLS=$(minikube service -n s3www minio --url)
MINIO_CONSOLE_URL=$(echo "$MINIO_URLS" | head -n 1)
MINIO_API_URL=$(echo "$MINIO_URLS" | tail -n 1)

S3WWW_URLS=$(minikube service -n s3www s3www --url)
S3WWW_APP_URL=$(echo "$S3WWW_URLS" | grep "8080" || echo "$S3WWW_URLS" | head -n 1)
S3WWW_METRICS_URL=$(echo "$S3WWW_URLS" | grep "9090" || echo "")

# Print success message
log_success "Deployment completed successfully!"
echo
echo -e "${GREEN}Service URLs:${NC}"
echo
echo -e "${BLUE}1. MinIO Service:${NC}"
echo -e "   • Console UI:  $MINIO_CONSOLE_URL"
echo -e "   • API Server: $MINIO_API_URL"
echo -e "   • Credentials:"
echo -e "     - Username: minioadmin"
echo -e "     - Password: minioadmin"
echo
echo -e "${BLUE}2. S3WWW Service:${NC}"
echo -e "   • Main Application: $S3WWW_APP_URL"
echo -e "   • Metrics Endpoint: $S3WWW_METRICS_URL/metrics"
echo
echo -e "${BLUE}3. Prometheus:${NC}"
echo -e "   • Dashboard: http://localhost:9090 (requires port-forwarding)"
echo -e "   • Command: kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo
echo -e "${YELLOW}Note:${NC} Each service exposes multiple endpoints:"
echo -e "  • MinIO: Console UI (management interface) and API server (S3 compatible endpoint)"
echo -e "  • S3WWW: Main application (file serving) and metrics endpoint (Prometheus metrics)"
echo -e "  • Prometheus: Single endpoint for metrics visualization"
echo
echo -e "${YELLOW}Port-forwarding alternatives:${NC}"
echo -e "  • MinIO: kubectl port-forward -n s3www svc/minio 9000:9000"
echo -e "  • S3WWW: kubectl port-forward -n s3www svc/s3www 8080:8080"
echo
log_info "Use Ctrl+C to stop port-forwarding when done"

# Instructions for accessing the services
echo "
To access the services:
1. MinIO Console: $MINIO_CONSOLE_URL
   - Username: minioadmin
   - Password: minioadmin

2. S3WWW Application: $S3WWW_APP_URL

3. Prometheus Dashboard: Run 'kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090'
   Then visit: http://localhost:9090
"