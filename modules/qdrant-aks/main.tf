# -----------------------------------------------------------------------------
# Qdrant AKS Module (prod)
# -----------------------------------------------------------------------------

resource "kubernetes_namespace_v1" "qdrant" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "qdrant"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

locals {
  # Build helm values as YAML for helm_release
  helm_values = yamlencode({
    replicaCount = var.replicas
    resources = {
      requests = {
        cpu    = var.resources.requests.cpu
        memory = var.resources.requests.memory
      }
      limits = {
        cpu    = var.resources.limits.cpu
        memory = var.resources.limits.memory
      }
    }
    persistence = {
      enabled      = var.persistence.enabled
      size         = var.persistence.size
      storageClass = var.persistence.storage_class
    }
    service = {
      type = var.service_type
    }
    nodeSelector = var.node_selector
  })
}

resource "helm_release" "qdrant" {
  name       = var.release_name
  repository = "https://qdrant.github.io/qdrant-helm"
  chart      = "qdrant"
  version    = var.chart_version
  namespace  = var.create_namespace ? kubernetes_namespace_v1.qdrant[0].metadata[0].name : var.namespace

  values = concat(
    [local.helm_values],
    var.additional_values != null ? [var.additional_values] : []
  )

  timeout = 600

  depends_on = [kubernetes_namespace_v1.qdrant]
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "qdrant" {
  count = var.enable_hpa ? 1 : 0
  metadata {
    name      = "${var.release_name}-hpa"
    namespace = var.create_namespace ? kubernetes_namespace_v1.qdrant[0].metadata[0].name : var.namespace
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "StatefulSet"
      name        = var.release_name
    }
    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_target_cpu_utilization
        }
      }
    }
    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_target_memory_utilization
        }
      }
    }
  }
  depends_on = [helm_release.qdrant]
}
