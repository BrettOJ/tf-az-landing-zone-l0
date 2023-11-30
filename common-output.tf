output "l0-resource-groups" {
  value = {
    name = module.resource_groups.rg_output
  }
}

output "l0-storage-account" {
  value = {
    name = module.l0_storage_account.sst_output
      }
  sensitive = true
}

output "loga_output" {
  value = {
    name = module.log_analytics_workspace.loga_output
    id = module.log_analytics_workspace.loga_output.id
  }
  sensitive = true
}

output "akv_output" {
  value = {
    name = module.azure_key_vault.akv_output
    id = module.azure_key_vault.akv_output.id
  }
  sensitive = true
}