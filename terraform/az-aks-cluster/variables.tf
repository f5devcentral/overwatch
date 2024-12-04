variable "resource_group_location" {
  type        = string
  default     = "canadacentral"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_name" {
  type        = string
  default     = "sh-Overwatch"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "aks_vnet" {
  type = string
  default = "Overwatch-subnet"
  description = "Vnet in which to instantiate AKS subnet"
}

variable "aks_node_subnet" {
  type = string
  default = "aks-node-subnet"
  description = "name of AKS node subnet to instantiate"
}

variable "aks_aci_subnet" {
  type = string
  default = "aks-aci-subnet"
  description = "name of AKS CNI subnet to instantiate"
}

variable "cluster_name" {
  type = string
  default = "aks-Sentinel"
  description = "Prefix of the AKS cluster to instantiate"
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 3
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azops"
}

variable "password" {
  type = string
  default = "Canada12345!"
  description = "The admin password for the new cluster"
}