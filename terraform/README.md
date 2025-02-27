# Terraform Deployment for s3www Stack

This Terraform configuration deploys the s3www stack to a Kubernetes cluster. The stack includes a MinIO S3-compatible storage server and a web server that serves files from MinIO.

## Prerequisites

- Terraform >= 1.0.0
- Kubernetes cluster
- `kubectl` configured with cluster access
- Helm v3

## Components

1. **MinIO Server**:
   - Deployed using Bitnami Helm chart
   - Standalone mode
   - Default credentials: minioadmin/minioadmin
   - Default bucket: s3www-files

2. **S3WWW Application**:
   - Custom web server
   - Serves files from MinIO
   - Prometheus metrics
   - Init container for file provisioning

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the configuration:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. Access the application:
   ```bash
   kubectl port-forward svc/s3www 8080:8080 -n s3www
   ```
   Visit: http://localhost:8080

## Configuration

### Required Variables

| Name | Description | Default |
|------|-------------|---------|
| namespace | Kubernetes namespace | s3www |
| minio_chart_version | MinIO Helm chart version | 12.6.4 |

### Optional Variables

| Name | Description | Default |
|------|-------------|---------|
| fileToServe.sourceUrl | URL of file to serve | https://media.giphy.com/media/VdiQKDAguhDSi37gn1/giphy.gif |
| fileToServe.initContainer.enabled | Enable init container | true |
| metrics.enabled | Enable Prometheus metrics | true |
| metrics.port | Metrics port | 9090 |

## Security

The deployment includes several security features:
- Non-root container execution
- ReadOnlyRootFilesystem
- Dedicated service account
- Resource limits and requests

## Cleanup

To remove all resources:
```bash
terraform destroy
```

## Troubleshooting

1. **Terraform State Lock**:
   ```bash
   # Remove state lock if needed
   rm -f .terraform.lock.hcl
   terraform init
   ```

2. **Helm Release Issues**:
   ```bash
   # Force replacement
   terraform taint helm_release.s3www
   terraform apply
   ```

3. **Resource Cleanup**:
   ```bash
   # Manual cleanup if needed
   kubectl delete namespace s3www
   ```
