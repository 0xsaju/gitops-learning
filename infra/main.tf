provider "azurerm" {
  features {}
  subscription_id = "c45812e8-7995-4894-9bd9-3f8d098368ca"
}

resource "azurerm_resource_group" "main" {
  name     = "myapp-rg"
  location = "southeastasia"
}

resource "azurerm_mysql_flexible_server" "main" {
  name                   = "myappmysql2024"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  administrator_login    = "appuser"
  administrator_password = "appPassword123!"
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  zone                   = "1"
  #public_network_access_enabled = true
}

resource "azurerm_mysql_flexible_database" "main" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_all" {
  name                = "AllowAllAzureIPs"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_service_plan" "main" {
  name                = "myapp-service-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "backend" {
  name                = "myapp-backend-2024"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }
  app_settings = {
    DB_HOST     = azurerm_mysql_flexible_server.main.fqdn
    DB_USER     = "appuser@myappmysql2024"
    DB_PASSWORD = "appPassword123!"
    DB_NAME     = "appdb"
    DB_PORT     = "3306"
    JWT_SECRET  = "supersecretkey"
    FRONTEND_URL = "https://myapp-frontend-2024.azurewebsites.net"
    PORT        = "4000"
  }
}

resource "azurerm_linux_web_app" "frontend" {
  name                = "myapp-frontend-2024"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }
  app_settings = {
    REACT_APP_API_URL = "https://${azurerm_linux_web_app.backend.default_hostname}"
  }
} 