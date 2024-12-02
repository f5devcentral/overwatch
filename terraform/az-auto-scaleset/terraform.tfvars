# BIG-IP Environment
f5_username = "azops"
f5_password = "Default123456"
ssh_key     = "~/.ssh/id_rsa.pub"
vnet_rg     = "sh-Overwatch"
vnet_name   = "Overwatch-subnet"
mgmtSubnet  = "mgmt-subnet"
extSubnet   = "external-subnet"
intSubnet   = "internal-subnet"
mgmtNsg     = "mgmtNsg"
extNsg      = "extNsg"
intNsg      = "intNsg"

# Azure Environment
location      = "canadacentral"
projectPrefix = "Sentinal"
resourceOwner = "s.hillier@f5.com"


instance_type = "Standard_DS5_v2"
product = "f5-big-ip-byol"
image_name = "f5-big-all-2slot-byol"
bigip_version = "17.1.1040100"

#Network
dns_suffix = "f5demo.com"
vm_name = "f5BigIp"

# Key Vault - Uncomment to use Key Vault integration
#az_keyvault_authentication = true
#keyvault_rg                = "myKv-rg-123"
#keyvault_name              = "myKv-123"
#user_identity              = "/subscriptions/xxxx/resourceGroups/myRg123/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myManagedId123"
