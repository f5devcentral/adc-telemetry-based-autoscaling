# Create Log Analytic Workspace

resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-analytics-workspace"
  sku                 = "PerNode"
  retention_in_days   = 300
  resource_group_name = data.azurerm_resource_group.bigiprg.name
  location            = data.azurerm_resource_group.bigiprg.location
}

resource "azurerm_log_analytics_solution" "sentinel" {
  solution_name         = "SecurityInsights"
  location            = data.azurerm_resource_group.bigiprg.location
  resource_group_name = data.azurerm_resource_group.bigiprg.name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}