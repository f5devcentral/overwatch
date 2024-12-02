# Generate random resource group name
resource "random_pet" "rg_name" {
  #prefix = var.resource_group_name_prefix
  prefix = var.resource_group_name
}

#resource "azurerm_resource_group" "rg" {
#  location = var.resource_group_location
#  name     = random_pet.rg_name.id
#}

data azurerm_resource_group "existing-rg" {
  name = var.resource_group_name
}

resource "random_pet" "azurerm_kubernetes_cluster_name" {
  prefix = "aks-Sentinel"
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "sentinel"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = data.azurerm_resource_group.existing-rg.location
  name                = random_pet.azurerm_kubernetes_cluster_name.id
  #resource_group_name = azurerm_resource_group.rg.name
  resource_group_name = var.resource_group_name
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id

  sku_tier = "Standard"
  cost_analysis_enabled = true
 
  identity {
    type = "SystemAssigned"
  }
  default_node_pool {
    name       = "aksnodepool"
    vm_size    = "Standard_DS5_v2"
    node_count = var.node_count
    vnet_subnet_id = azurerm_subnet.aks-node-subnet.id
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }
  aci_connector_linux {
    subnet_name = azurerm_subnet.aks-aci-subnet.name
  }
  network_profile {
    network_plugin    = "azure"
    network_policy = "azure"
    load_balancer_sku = "standard"
  }
  azure_policy_enabled             = false
  http_application_routing_enabled = false
}