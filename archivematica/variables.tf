# Azure Variables
variable "subscription_id" {
    description = "Azure subscription ID"
}
variable "client_id" {
    description = "Azure client ID. Optional."
    default = ""
}
variable "client_secret" {
    description = "Azure client secret. Optional."
    default = ""
}
variable "tenant_id" {
    description = "Azure tenant ID."
}
variable "public_key" {
  description = "Provide a valid public SSH key"
  default = ""
}

variable "location" {
  description = "Location of the azure resource group. Default is London."
  default = "northeurope"
}

variable "account_tier" {
  default = "Standard"
}

variable "vm_size" {
  default = "Standard_B1s"
}

 variable "developer_access" {
  type = "list"
  default = []
}
variable "user_access" {
  type = "list"
  default = []
}
variable "owner" { }

variable "name" {
  default = "terraform"
}
variable "namespace" {
  default = "leaf"
}
variable "stage" {
  default = "dev"
}

variable "environment" { 
  default = "dev"
}

variable "namespace-org" {
  default = true
}

variable "org" {
  default = "leaf"
}

variable "service" {
  default = ""
}

variable "product" {
  default = ""
}

variable "team" {
  default = "research-technologies"
}

# Used for adding the DNS A Record
variable "zone_name" {
  default = ""
}

variable "zone_resource_group" {
  default = ""
}

variable "server_user" {
  description= "User for the server, normally azureuser"
  default = "azureuser"
}

variable "shared_resource_group_name" { }

variable "fileshare_account_name" { }
variable "fileshare_account_key" { }
variable "fileshare_name" { }
