variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Kubernetes namespace for s3www stack"
  type        = string
  default     = "s3www"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "namespace_labels" {
  description = "Additional labels to add to the namespace"
  type        = map(string)
  default     = {}
}

variable "namespace_annotations" {
  description = "Additional annotations to add to the namespace"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment (e.g., development, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "s3www-stack"
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = "../s3www-stack"
}

variable "values_file" {
  description = "Path to the values file"
  type        = string
  default     = "../s3www-stack/values.yaml"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600
}

variable "helm_set_values" {
  description = "Map of values to set via helm set"
  type        = map(string)
  default     = {}
}

variable "minio_root_user" {
  description = "MinIO root user"
  type        = string
  sensitive   = true
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}

variable "minio_chart_version" {
  description = "MinIO Helm chart version"
  type        = string
  default     = "12.8.9"
}

variable "enable_metrics" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "enable_servicemonitor" {
  description = "Enable ServiceMonitor for Prometheus Operator"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable Ingress"
  type        = bool
  default     = false
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Hostname for the ingress"
  type        = string
  default     = "s3www.local"
}

variable "file_to_serve_url" {
  description = "URL of the file to serve"
  type        = string
  default     = "https://raw.githubusercontent.com/codeium/s3www/main/README.md"
}
