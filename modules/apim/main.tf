# -----------------------------------------------------------------------------
# API Management Module
# -----------------------------------------------------------------------------

resource "azurerm_api_management" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_api_management_product" "products" {
  for_each              = { for product in var.products : product.id => product }
  product_id            = each.value.id
  api_management_name   = azurerm_api_management.main.name
  resource_group_name   = var.resource_group_name
  display_name          = each.value.display_name
  description           = each.value.description
  subscription_required = each.value.subscription_required
  approval_required     = each.value.approval_required
  published             = each.value.published
}

resource "azurerm_api_management_api" "apis" {
  for_each            = { for api in var.apis : api.name => api }
  name                = each.value.name
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  revision            = each.value.revision
  display_name        = each.value.display_name
  path                = each.value.path
  protocols           = each.value.protocols
  service_url         = each.value.backend_url

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }
}

resource "azurerm_api_management_product_api" "links" {
  for_each            = { for link in var.api_product_links : "${link.api_name}-${link.product_id}" => link }
  api_name            = azurerm_api_management_api.apis[each.value.api_name].name
  product_id          = azurerm_api_management_product.products[each.value.product_id].product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_policy" "global" {
  count             = var.global_policy != null ? 1 : 0
  api_management_id = azurerm_api_management.main.id
  xml_content       = var.global_policy
}

resource "azurerm_api_management_logger" "app_insights" {
  name                = "app-insights"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  resource_id         = var.app_insights_id

  application_insights {
    instrumentation_key = var.app_insights_instrumentation_key
  }
}

resource "azurerm_api_management_diagnostic" "app_insights" {
  identifier               = "applicationinsights"
  api_management_name      = azurerm_api_management.main.name
  resource_group_name      = var.resource_group_name
  api_management_logger_id = azurerm_api_management_logger.app_insights.id

  sampling_percentage       = 100
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"
}
