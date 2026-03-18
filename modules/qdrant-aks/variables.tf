variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "qdrant"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "qdrant"
}

variable "create_namespace" {
  description = "Create namespace if not exists"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = null
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 3
}

variable "resources" {
  description = "Resource requests and limits"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "8Gi"
    }
  }
}

variable "persistence" {
  description = "Persistence configuration"
  type = object({
    enabled       = bool
    size          = string
    storage_class = string
  })
  default = {
    enabled       = true
    size          = "50Gi"
    storage_class = "managed-premium"
  }
}

variable "node_selector" {
  description = "Node selector labels"
  type        = map(string)
  default = {
    "workload" = "qdrant"
  }
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
}

variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = true
}

variable "hpa_min_replicas" {
  description = "HPA minimum replicas"
  type        = number
  default     = 3
}

variable "hpa_max_replicas" {
  description = "HPA maximum replicas"
  type        = number
  default     = 6
}

variable "hpa_target_cpu_utilization" {
  description = "HPA target CPU utilization"
  type        = number
  default     = 70
}

variable "hpa_target_memory_utilization" {
  description = "HPA target memory utilization"
  type        = number
  default     = 80
}

variable "additional_values" {
  description = "Additional Helm values as YAML string"
  type        = string
  default     = null
}
