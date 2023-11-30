
locals {
  tags = {
    "created-by" = "Terraform"

  }

  metadata = {
    "key1" = "value1"
    "key2" = "value2"
  }

  naming_convention_info = {
    name         = "001"
    project_code = "knj"
    env          = "dev"
    zone         = "z1"
    agency_code  = "konjur"
    tier         = "dta"
  }

  solution_plan_map = {
    "OEM"   = "OMS"
    "PAYG"  = "PAYG"
    "Azure" = "Azure"
  }
}

data "azurerm_client_config" "current" {}

module "resource_groups" {
  source = "git::https://github.com/BrettOJ/tf-az-module-resource-group?ref=main"
  resource_groups = {
    1 = {
      name                   = var.l0_resource_group_name
      location               = var.location
      naming_convention_info = local.naming_convention_info
      tags                   = local.tags
    }
  }
}

module "log_analytics_workspace" {
  source                 = "git::https://github.com/BrettOJ/tf-az-module-log-analytics?ref=main"
  resource_group_name    = module.resource_groups.rg_output.1.name
  location               = var.location
  sku                    = "PerGB2018"
  naming_convention_info = local.naming_convention_info
  tags                   = local.tags
  solution_plan_map      = null #local.solution_plan_map 
}


module "l0_storage_account" {
  source              = "git::https://github.com/BrettOJ/tf-az-module-storage-account?ref=main"
  resource_group_name = module.resource_groups.rg_output.1.name
  location            = var.location
  kind                = "StorageV2"
  sku                 = "Standard_LRS"
  access_tier         = "Hot"
  assign_identity     = "SystemAssigned"
  #public_network_access_enabled = var.public_network_access_enabled
  containers = {
    lvl0 = {
      name        = "lvl0"
      access_type = "private"
    }
    lvl1 = {
      name        = "lvl1"
      access_type = "private"
    }
    lvl2 = {
      name        = "lvl2"
      access_type = "private"
    }
  }
  diag_object = {
    log_analytics_workspace_id = module.log_analytics_workspace.loga_output.id
    enabled_log = [
      ["StorageDelete", true, true, 80],
    ]
    metric = [
      ["AllMetrics", true, true, 80],
    ]
  }

  naming_convention_info = local.naming_convention_info
  tags                   = local.tags
}

module "azure_key_vault" {
  source              = "git::https://github.com/BrettOJ/tf-az-module-key-vault?ref=main"
  resource_group_name = module.resource_groups.rg_output.1.name
  location            = var.location
  sku                 = "premium"
  akv_policies = {
    sp2 = {
      object_id          = data.azurerm_client_config.current.object_id
      tenant_id          = data.azurerm_client_config.current.tenant_id
      key_permissions    = ["Create", "Get", "Delete", "Update", "GetRotationPolicy", "Recover" ]
      secret_permissions = ["Get", "List", "Set", "Delete"]
    }
  }
  network_acls = [
    {
      bypass         = "AzureServices"
      default_action = "Allow"
      ip_rules       = null
      subnet_ids     = null
    }
  ]

  akv_features = {
    enable_disk_encryption     = true
    enable_deployment          = true
    enable_template_deployment = true
  }
  diag_object = {
    log_analytics_workspace_id = module.log_analytics_workspace.loga_output.id
    enabled_log = [
      ["AuditEvent", true, true, 80],
    ]
    metric = [
      ["AllMetrics", true, true, 80],
    ]
  }
  naming_convention_info = local.naming_convention_info
  tags                   = local.tags
}


module "managed_user_identity" {

  source                 = "git::https://github.com/BrettOJ/tf-az-module-auth-user-msi?ref=main"
  resource_group_name    = module.resource_groups.rg_output.1.name
  location               = var.location
  naming_convention_info = local.naming_convention_info
  tags                   = local.tags

}

module "azurerm_key_vault_secret" {
    source = "git::https://github.com/BrettOJ/tf-az-module-key-vault-secret?ref=main"
    key_vault_secrets = {
        001 = {
        key         = "tenantid"
        value        = "f3c9952d-3ea5-4539-bd9a-7e1093f8a1b6"
            }
        002 = {
        key         = "subscriptionsid"
        value        = "95328200-66a3-438f-9641-aeeb101e5e37"
            }
    }
    key_vault_id = module.azure_key_vault.akv_output.id
    naming_convention_info = local.naming_convention_info
    tags = local.tags
}