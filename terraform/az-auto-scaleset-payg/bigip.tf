# BIG-IP Cluster

############################ Onboard Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    f5_username                = var.f5_username
    f5_password                = var.az_keyvault_authentication ? "" : var.f5_password
    az_keyvault_authentication = var.az_keyvault_authentication
    vault_url                  = var.az_keyvault_authentication ? data.azurerm_key_vault.main[0].vault_uri : ""
    keyvault_secret            = var.az_keyvault_authentication ? var.keyvault_secret : ""
    ssh_keypair                = file(var.ssh_key)
    INIT_URL                   = var.INIT_URL
    DO_URL                     = var.DO_URL
    AS3_URL                    = var.AS3_URL
    TS_URL                     = var.TS_URL
    FAST_URL                   = var.FAST_URL
    REG_KEY                    = var.f5_license_keys[azurerm_linux_virtual_machine_scale_set.f5vmss.instance]
    WEBTOP_URL                 = var.WEBTOP_URL
    WEBSSH_URL                 = var.WEBSSH_URL
    DO_VER                     = split("-", var.DO_URL)[4]
    AS3_VER                    = split("-", var.AS3_URL)[4]
    TS_VER                     = split("-", var.TS_URL)[4]
    FAST_VER                   = split("-", var.FAST_URL)[4]
    dns_server                 = var.dns_server
    dns_suffix                 = var.dns_suffix
    ntp_server                 = var.ntp_server
    timezone                   = var.timezone
    law_id                     = azurerm_log_analytics_workspace.main.workspace_id
    law_primkey                = azurerm_log_analytics_workspace.main.primary_shared_key
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
resource "azurerm_linux_virtual_machine_scale_set" "f5vmss" {
  name                 = format("f5vmss-%s", var.projectPrefix)
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  sku                  = var.instance_type
  instances            = var.instances
  admin_username       = var.f5_username
  admin_password       = var.f5_password
  disable_password_authentication = false
  computer_name_prefix = var.vm_name == "" ? "f5vm-${var.projectPrefix}" : var.vm_name
  custom_data          = base64encode(local.f5_onboard1)

  #admin_ssh_key {
  #  public_key = file(var.ssh_key)
  #  username   = var.f5_username
  #}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  source_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
  }

  network_interface {
    name    = "mgmt"
    primary = true
    ip_configuration {
      name      = "mgmt"
      primary   = true
      subnet_id = data.azurerm_subnet.mgmt.id
      public_ip_address {
        name = "mgmt-pip"
      }
    }
  }

  network_interface {
    name    = "external"
    primary = false
    ip_configuration {
      name      = "primary"
      primary   = true
      subnet_id = data.azurerm_subnet.external.id

      public_ip_address {
        name = "selfip-pip"
      }
    }
    ip_configuration {
      name                                   = "secondary"
      primary                                = false
      subnet_id                              = data.azurerm_subnet.external.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  network_interface {
    name    = "internal"
    primary = false
    ip_configuration {
      name      = "primary"
      primary   = true
      subnet_id = data.azurerm_subnet.internal.id
    }
    ip_configuration {
      name      = "secondary"
      primary   = false
      subnet_id = data.azurerm_subnet.internal.id
    }
  }

  tags = {
    owner = var.resourceOwner
  }
}
