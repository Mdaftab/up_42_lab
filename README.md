# S3WWW - Kubernetes File Serving Application

A production-ready file serving application that integrates MinIO S3-compatible storage with Prometheus monitoring in a Kubernetes environment. The application serves files from MinIO with metrics collection, making it suitable for both development and production use.

## 🚀 Features

- **Automated Deployment**: Single-command deployment using Minikube or any Kubernetes cluster
- **S3-Compatible Storage**: MinIO integration for reliable file storage
- **Monitoring & Metrics**:
  - Prometheus metrics integration
  - Custom metrics for request tracking
  - Built-in ServiceMonitor for auto-discovery
- **Security**:
  - Non-root container execution
  - Configurable security contexts
  - CORS support
- **Developer Experience**:
  - Terraform-based infrastructure
  - Helm chart deployment
  - Automatic file provisioning
  - NodePort service exposure

## 📋 Prerequisites

The following tools are required:
- Minikube v1.25.0+
- Kubernetes v1.25.0+
- Helm v3+
- Terraform v1.0+
- Docker
- kubectl

### Installing Prerequisites on Ubuntu

We provide a script to automatically install all required tools on Ubuntu:

```bash
# Make the script executable
chmod +x install_prerequisites.sh

# Run the installation script with sudo
sudo ./install_prerequisites.sh
```

The script will:
1. Install Docker and add your user to the docker group
2. Install kubectl and configure it
3. Install Minikube with the latest version
4. Install Helm package manager
5. Install Terraform
6. Install other required dependencies

After installation:
1. Log out and log back in for group changes to take effect
2. Verify installation with:
   ```bash
   docker --version
   minikube version
   kubectl version --client
   helm version
   terraform version
   ```

## 🛠 Architecture

The application consists of three main components:

1. **S3WWW Application**:
   - Main file serving application (port 8080)
   - Prometheus metrics endpoint (port 9090)
   - Custom metrics for request tracking

2. **MinIO Service**:
   - S3-compatible object storage
   - Management Console UI
   - S3 API endpoint

3. **Monitoring Stack**:
   - Prometheus Operator
   - ServiceMonitor for metrics collection
   - Metrics visualization

## 📦 Installation

### One-Click Deployment

After installing prerequisites, deploy the application:
```bash
./deploy_s3www_app.sh
```

This deployment script will:
1. Verify all required tools are installed
2. Start Minikube if not running
3. Enable required Kubernetes addons (ingress, metrics-server)
4. Install and configure Prometheus Operator for monitoring
5. Deploy MinIO using Helm for S3-compatible storage
6. Build and deploy the S3WWW application
7. Configure metrics collection and ServiceMonitor
8. Expose services via NodePort
9. Display all service URLs and access information

### Manual Deployment

1. **Start Minikube**:
   ```bash
   minikube start --kubernetes-version=v1.25.0
   ```

2. **Deploy Infrastructure**:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

3. **Build Application**:
   ```bash
   cd s3www
   docker build -t s3www:latest .
   ```

## 🏗 Project Structure

```
.
├── install_prerequisites.sh    # Tool installation script
├── deploy_s3www_app.sh        # Application deployment script
├── s3www-stack/              # Helm chart for S3WWW application
│   ├── Chart.yaml
│   ├── values.yaml           # Default values
│   └── templates/            # Kubernetes manifests
├── terraform/                # Infrastructure as Code
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions
│   ├── values-development.yaml  # Development environment config
│   └── values-production.yaml   # Production environment config
└── README.md
```

## 🔄 Environment Configurations

The project supports both development and production environments through separate configuration files:

### Development Environment (`values-development.yaml`)
- Optimized for local development using Minikube
- Reduced resource requests and limits
- Development-focused logging levels
- NodePort service exposure
- Local storage configuration
- Metrics enabled but with basic configuration

### Production Environment (`values-production.yaml`)
- Production-grade configuration
- High availability settings
- Proper resource allocation
- LoadBalancer service type
- Persistent volume claims
- Enhanced security settings
- Full metrics and monitoring setup

### Switching Environments

To deploy to a specific environment:

```bash
# For development (default)
./deploy_s3www_app.sh

# For production
./deploy_s3www_app.sh --env production
```

### Key Configuration Differences

| Feature                | Development                | Production               |
|-----------------------|---------------------------|--------------------------|
| Storage               | Local ephemeral           | Persistent volumes      |
| Service Type          | NodePort                 | LoadBalancer           |
| Resource Requests     | Minimal                  | Production-sized       |
| Replicas             | Single                   | Multiple (HA)          |
| Security             | Basic                    | Enhanced               |
| Monitoring           | Basic metrics            | Full monitoring stack  |
| Logging              | Debug level              | Info level            |
| Backup Strategy      | None                     | Automated backups     |

## 📊 Installation

### One-Click Deployment

After installing prerequisites, deploy the application:
```bash
./deploy_s3www_app.sh
```

This deployment script will:
1. Verify all required tools are installed
2. Start Minikube if not running
3. Enable required Kubernetes addons (ingress, metrics-server)
4. Install and configure Prometheus Operator for monitoring
5. Deploy MinIO using Helm for S3-compatible storage
6. Build and deploy the S3WWW application
7. Configure metrics collection and ServiceMonitor
8. Expose services via NodePort
9. Display all service URLs and access information

### Manual Deployment

1. **Start Minikube**:
   ```bash
   minikube start --kubernetes-version=v1.25.0
   ```

2. **Deploy Infrastructure**:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

3. **Build Application**:
   ```bash
   cd s3www
   docker build -t s3www:latest .
   ```

## # Scripts

The project includes two main scripts:

1. **install_prerequisites.sh**:
   - Installs all required tools and dependencies
   - Sets up Docker, Kubernetes, Minikube, Helm, and Terraform
   - Configures user permissions and groups
   - Verifies successful installation

2. **deploy_s3www_app.sh**:
   - Handles complete application deployment
   - Sets up Kubernetes environment
   - Deploys all components (MinIO, S3WWW, Prometheus)
   - Configures monitoring and metrics
   - Provides access URLs for all services

## 🌐 Accessing Services

After deployment, the following services are available:

1. **MinIO Service**:
   - Console UI: http://<minikube-ip>:<nodeport>
   - API Server: http://<minikube-ip>:<nodeport>
   - Default credentials:
     - Username: minioadmin
     - Password: minioadmin

2. **S3WWW Service**:
   - Main Application: http://<minikube-ip>:<nodeport>
   - Metrics Endpoint: http://<minikube-ip>:<nodeport>/metrics

3. **Prometheus**:
   - Dashboard: http://localhost:9090 (requires port-forwarding)
   - Command: `kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090`

## 📊 Monitoring & Metrics

The application exposes the following custom metrics:

1. **Request Metrics**:
   - `s3www_requests_total`: Total number of requests by path
   - `s3www_request_duration_seconds`: Request processing duration

2. **System Metrics**:
   - Standard Go metrics (goroutines, memory, etc.)
   - HTTP server metrics

Access metrics at: `http://<service-url>/metrics`

## 🔧 Configuration

### Application Configuration

```yaml
metrics:
  enabled: true
  port: 9090
  serviceMonitor:
    enabled: true

service:
  type: NodePort
  port: 8080
```

### MinIO Configuration

```yaml
minio:
  persistence:
    enabled: true
    size: 10Gi
  resources:
    requests:
      memory: 256Mi
    limits:
      memory: 512Mi
```

## 🔍 Troubleshooting

1. **Check Pod Status**:
   ```bash
   kubectl get pods -n s3www
   ```

2. **View Logs**:
   ```bash
   kubectl logs -l app.kubernetes.io/name=s3www -n s3www
   ```

3. **Verify Metrics**:
   ```bash
   curl http://<service-url>/metrics
   ```

4. **Common Issues**:
   - Ensure Minikube is running
   - Check MinIO credentials
   - Verify service NodePorts are accessible
   - Confirm Prometheus ServiceMonitor is working

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
