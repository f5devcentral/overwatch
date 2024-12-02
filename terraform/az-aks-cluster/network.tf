data azurerm_virtual_network "exiting-vnet" {
  resource_group_name = var.resource_group_name
  name = var.aks_vnet
}

# Public IP address for NAT gateway
resource "azurerm_public_ip" "my_public_ip" {
  name                = "aks-natgw-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT Gateway
resource "azurerm_nat_gateway" "my_nat_gateway" {
  name                = "aks-natgw"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

# Associate NAT Gateway with Public IP
resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.my_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.my_public_ip.id
}

# Associate NAT Gateway with Subnet
resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = azurerm_subnet.aks-subnet.id
  nat_gateway_id = azurerm_nat_gateway.my_nat_gateway.id
}

resource azurerm_subnet "aks-subnet" {
  resource_group_name = var.resource_group_name
  name = var.aks_subnet
  virtual_network_name = var.aks_vnet
  address_prefixes = ["10.112.0.0/15"]
  delegation {
    name = "aciDelegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }  
}
