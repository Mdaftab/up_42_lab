terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

data "kubernetes_namespace" "existing" {
  count = var.create_namespace ? 0 : 1
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "s3www" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "s3www-stack"
    }
  }
}

locals {
  namespace = var.namespace
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "s3www-stack"
    "app.kubernetes.io/environment" = var.environment
  }
}

resource "helm_release" "minio" {
  name       = "minio"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "minio"
  version    = var.minio_chart_version
  namespace  = var.namespace

  values = [
    <<-EOT
    mode: standalone

    ## Set default rootUser and rootPassword
    auth:
      rootUser: minioadmin
      rootPassword: minioadmin

    ## Enable persistence using Persistent Volume Claims
    persistence:
      enabled: true
      size: 10Gi

    ## Configure resource requests and limits
    resources:
      requests:
        memory: 256Mi
        cpu: 250m
      limits:
        memory: 512Mi
        cpu: 500m

    ## Create a default bucket
    defaultBuckets: "s3www-files"

    ## Configure the service to be accessible
    service:
      type: NodePort
      port: 9000

    ## Configure MinIO to run in standalone mode
    statefulset:
      replicaCount: 1
    EOT
  ]

  wait = true
}

resource "helm_release" "s3www" {
  name       = "s3www"
  chart      = "${path.module}/../s3www-stack"
  namespace  = var.namespace
  depends_on = [helm_release.minio]

  set {
    name  = "minio.endpoint"
    value = "minio.${var.namespace}.svc.cluster.local:9000"
  }

  set {
    name  = "minio.rootUser"
    value = "minioadmin"
  }

  set {
    name  = "minio.rootPassword"
    value = "minioadmin"
  }

  set {
    name  = "fileToServe.initContainer.enabled"
    value = "true"
  }

  set {
    name  = "fileToServe.sourceUrl"
    value = "https://media.giphy.com/media/VdiQKDAguhDSi37gn1/giphy.gif"
  }

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "metrics.serviceMonitor.enabled"
    value = "true"
  }
}
