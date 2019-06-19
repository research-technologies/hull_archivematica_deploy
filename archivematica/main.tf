# with AZURE

provider "azurerm" { 
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
}

module "labels" {
  source = "devops-workflow/label/local"
  version = "0.2.1"

  # Required
  environment = "${var.environment}"
  name = "${var.name}"
  # Optional
  namespace-org = "${var.namespace-org}"
  organization = "${var.org}"
  delimiter = "-"
  owner = "${var.owner}"
  team = "${var.team}"
  tags {
    Name = "${module.labels.id}"
  }
}

# Use a separate module to add a dns A record
module "terraform_azure_dns_arecord_hyrax" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_dns_arecord.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "${var.name}"
  
  zone_name = "${var.zone_name}"
  zone_resource_group = "${var.zone_resource_group}"
  record = "${azurerm_public_ip.publicip.ip_address}"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

resource "azurerm_virtual_network" "network" {
    name = "${module.labels.id}-vnet"
    address_space = ["10.0.0.0/16"]
    location = "${var.location}"
    resource_group_name = "${var.shared_resource_group_name}"

    tags = "${module.labels.tags}"
}

resource "azurerm_subnet" "subnet" {
    name = "${module.labels.id}-subnet"
    resource_group_name = "${var.shared_resource_group_name}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix = "10.0.2.0/24"
}

resource "azurerm_public_ip" "publicip" {
  name = "${module.labels.id}-publicip"
  location = "${var.location}"
  resource_group_name = "${var.shared_resource_group_name}"
  allocation_method = "Static"

  tags = "${module.labels.tags}"
}

resource "azurerm_network_security_group" "security_groups" {
    name = "${module.labels.id}"
    location = "${var.location}"
    resource_group_name = "${var.shared_resource_group_name}"

    security_rule {
        name = "allow-all-developer"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "TCP"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefixes = "${var.developer_access}"
        destination_address_prefix = "*"
    }
    security_rule {
        name = "allow-all-users"
        priority = 1002
        direction = "Inbound"
        access = "Allow"
        protocol = "TCP"
        source_port_range = "80"
        destination_port_range = "80"
        source_address_prefixes = "${var.user_access}"
        destination_address_prefix = "*"
    }

    tags = "${module.labels.tags}"
}

resource "azurerm_network_interface" "nic" {
    name = "${module.labels.id}-nic"
    location = "${var.location}"
    resource_group_name = "${var.shared_resource_group_name}"
    network_security_group_id = "${azurerm_network_security_group.security_groups.id}"
    

    ip_configuration {
        name = "${module.labels.id}-ipconf"
        subnet_id = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = "${azurerm_public_ip.publicip.id}"
    }

    tags = "${module.labels.tags}"
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${var.shared_resource_group_name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "storageaccount" {
    name = "diag${random_id.randomId.hex}"
    resource_group_name = "${var.shared_resource_group_name}"
    location = "${var.location}"
    account_replication_type = "LRS"
    account_tier = "${var.account_tier}"

    tags = "${module.labels.tags}"
}

resource "azurerm_virtual_machine" "vm" {

    depends_on = ["azurerm_network_interface.nic"]

    name = "${module.labels.id}-vm"
    location = "${var.location}"
    resource_group_name = "${var.shared_resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.nic.id}"]
    vm_size = "${var.vm_size}"

    storage_os_disk {
        name = "${module.labels.id}"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    # https://azuremarketplace.microsoft.com/en-us/marketplace/apps/RogueWave.CentOSbased75?tab=Overview
    storage_image_reference = {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "18.04-LTS"
      version = "latest"
    }

    os_profile {
        computer_name = "${module.labels.id}-vm"
        admin_username = "${var.server_user}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/${var.server_user}/.ssh/authorized_keys"
            key_data = "${var.public_key}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.storageaccount.primary_blob_endpoint}"
    }

    tags = "${module.labels.tags}"
    
  }
  
  resource "null_resource" "copy_scripts" {
  
    depends_on = ["azurerm_virtual_machine.vm"]
  
    connection {
      type     = "ssh"
      host     = "${azurerm_public_ip.publicip.ip_address}"
      user     = "${var.server_user}"
      private_key = "${file("/home/ec2-user/.ssh/id_rsa")}"
      agent    = false
      timeout  = "10m"
    }
  
    provisioner "file" {
      content = "${data.template_file.mount_script.rendered}"
      destination = "/home/azureuser/archivematica-mount.sh"
    }
    
    provisioner "file" {
      source = "archivematica-install.sh"
      destination = "/home/azureuser/archivematica-install.sh"
    }
  }

resource "azurerm_storage_account" "archivematica" {
  name = "${var.org}${var.environment}${var.name}"
  resource_group_name = "${var.shared_resource_group_name}"
  location = "${var.location}"
  account_tier = "${var.account_tier}"
  account_replication_type = "LRS" # add as a var
  account_kind = "StorageV2"
  access_tier = "Cool"
}

resource "azurerm_storage_container" "archivematica" {
  name = "${azurerm_storage_account.archivematica.name}"
  resource_group_name = "${var.shared_resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.archivematica.name}"
  container_access_type = "private"
}

data "template_file" "mount_script" {
  template = "${file("${path.cwd}/archivematica-mounts.tpl")}"
  vars = {
    blob_account_name = "${azurerm_storage_account.archivematica.name}"
    blob_account_key = "${azurerm_storage_account.archivematica.primary_access_key}"
    blob_container_name = "${azurerm_storage_container.archivematica.name}"
    fileshare_account_name = "${var.fileshare_account_name}"
    fileshare_account_key = "${var.fileshare_account_key}"
    fileshare_name = "${var.fileshare_name}"
  }
}
