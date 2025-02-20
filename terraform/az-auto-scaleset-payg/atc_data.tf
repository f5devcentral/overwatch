# VM01 DO Declaration from template
data "template_file" "ScScADC-F5VM01_F5-do_json" {
    template = "${file("${path.module}/templates/f5_do.tmpl.json")}"
    vars = {
        regkey         = "LBZRD-MGMGU-ZKROE-DAONR-XINJLCK"
        host1          = "ScScADC-F5VM01-F5"
        host2          = "ScScADC-F5VM02-F5"
        domainname     = "csd.local"
        local_host     = "ScScADC-F5VM01-F5"
        local_selfip1  = azurerm_network_interface.ScScADC-F5VM01_F5-nic2.private_ip_addresses[0]
        local_selfip2  = azurerm_network_interface.ScScADC-F5VM01_F5-nic3.private_ip_addresses[0]
        remote_selfip  = azurerm_network_interface.ScScADC-F5VM01_F5-nic1.private_ip_addresses[0]
        dns_server1    = "8.8.8.8"
        dns_server2    = "168.63.129.16"
        ntp_server     = "ntp.cira.ca"
        gateway        = "${cidrhost(azurerm_subnet.ScPcCNR-VDC_Core-External_F5-snet.address_prefix, 1)}" //"100.96.184.1"
        int_gateway    = "${cidrhost(azurerm_subnet.ScPcCNR-VDC_Core-Transit_F5-snet.address_prefix, 1)}" //"100.96.185.1"
        int_cidr       = "10.101.0.0/16"
        paz_cidr       = "192.168.0.0/16"
        sandbox_cidr   = "172.168.0.0/16"
        timezone       = "UTC"
        banner_color   = "red"
        admin_user     = "azops"
        admin_pass     = "Canada12345"
    }
}


# VM02 DO Declaration from template
data "template_file" "ScScADC-F5VM02_F5-do_json" {
    template = "${file("${path.module}/templates/f5_do.tmpl.json")}"
    vars = {
        regkey         = "DIYMH-YZMUX-HMDWG-UKVXZ-EIQDGIA"
        host1          = "ScScADC-F5VM01-F5"
        host2          = "ScScADC-F5VM02-F5"
        domainname     = "csd.local"
        local_host     = "ScScADC-F5VM02-F5"
        local_selfip1  = azurerm_network_interface.ScScADC-F5VM02_F5-nic2.private_ip_addresses[0]
        local_selfip2  = azurerm_network_interface.ScScADC-F5VM02_F5-nic3.private_ip_addresses[0]
        remote_selfip  = azurerm_network_interface.ScScADC-F5VM01_F5-nic1.private_ip_addresses[0]
        dns_server1    = "8.8.8.8"
        dns_server2    = "168.63.129.16"
        ntp_server     = "ntp.cira.ca"
        gateway        = "${cidrhost(azurerm_subnet.ScPcCNR-VDC_Core-External_F5-snet.address_prefix, 1)}" //"100.96.184.1"
        int_gateway    = "${cidrhost(azurerm_subnet.ScPcCNR-VDC_Core-Transit_F5-snet.address_prefix, 1)}" //"100.96.185.1"
        int_cidr       = "10.101.0.0/16"
        paz_cidr       = "192.168.0.0/16"
        sandbox_cidr   = "172.168.0.0/16"
        timezone       = "UTC"
        banner_color   = "red"
        admin_user     = "azops"
        admin_pass     = "Canada12345"
    }
}

# TS Declaration from template
data "template_file" "ScScADC-F5VM01_F5-ts_json" {
    template = "${file("${path.module}/templates/f5_ts.tmpl.json")}"
    depends_on = [azurerm_log_analytics_workspace.ScPcCSDF5law]
    vars = {
        law_id = "${azurerm_log_analytics_workspace.ScPcCSDF5law.workspace_id}"
        law_primkey = "${azurerm_log_analytics_workspace.ScPcCSDF5law.primary_shared_key}"
        location = "canadaCentral"
    }
}



# AS3 TS Declaration from template
data "template_file" "ScScADC-F5VM01_F5-as3_ts_json" {
template = "${file("${path.module}/templates/f5_as3_ts.tmpl.json")}"
    vars = {
        webssh_vs_addr = azurerm_subnet.ScPcCNR-VDC_Core-External_F5-snet.address_prefix
    }
}


