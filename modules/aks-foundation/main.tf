# -----------------------------------------------------------------------------
# AKS Foundation Module
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : var.name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_nodepool.vm_size
    node_count                   = var.system_nodepool.enable_auto_scaling ? null : var.system_nodepool.node_count
    min_count                    = var.system_nodepool.enable_auto_scaling ? var.system_nodepool.min_count : null
    max_count                    = var.system_nodepool.enable_auto_scaling ? var.system_nodepool.max_count : null
    auto_scaling_enabled         = var.system_nodepool.enable_auto_scaling
    vnet_subnet_id               = var.subnet_id
    os_disk_size_gb              = var.system_nodepool.os_disk_size_gb
    zones                        = var.availability_zones
    only_critical_addons_enabled = true
    node_labels                  = { "nodepool-type" = "system" }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  oidc_issuer_enabled       = var.enable_oidc_issuer
  workload_identity_enabled = var.enable_workload_identity

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_rbac ? [1] : []
    content {
      azure_rbac_enabled = true
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  dynamic "monitor_metrics" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      annotations_allowed = null
      labels_allowed      = null
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each              = { for pool in var.user_nodepools : pool.name => pool }
  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  auto_scaling_enabled  = each.value.enable_auto_scaling
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = each.value.os_disk_size_gb
  zones                 = var.availability_zones
  mode                  = "User"
  node_labels           = merge({ "nodepool-type" = "user", "workload" = each.value.name }, each.value.node_labels)
  node_taints           = each.value.node_taints
  tags                  = var.tags
}
