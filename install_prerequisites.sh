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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Update package list
log_info "Updating package list..."
apt-get update

# Install common dependencies
log_info "Installing common dependencies..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

# Install Docker if not present
if ! command_exists docker; then
    log_info "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    usermod -aG docker $SUDO_USER
    log_success "Docker installed successfully"
else
    log_info "Docker is already installed"
fi

# Install kubectl if not present
if ! command_exists kubectl; then
    log_info "Installing kubectl..."
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubectl
    log_success "kubectl installed successfully"
else
    log_info "kubectl is already installed"
fi

# Install Minikube if not present
if ! command_exists minikube; then
    log_info "Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    log_success "Minikube installed successfully"
else
    log_info "Minikube is already installed"
fi

# Install Helm if not present
if ! command_exists helm; then
    log_info "Installing Helm..."
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
    apt-get update
    apt-get install -y helm
    log_success "Helm installed successfully"
else
    log_info "Helm is already installed"
fi

# Install Terraform if not present
if ! command_exists terraform; then
    log_info "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update
    apt-get install -y terraform
    log_success "Terraform installed successfully"
else
    log_info "Terraform is already installed"
fi

log_success "All prerequisites have been installed successfully!"
log_info "Please log out and log back in for group changes to take effect."
