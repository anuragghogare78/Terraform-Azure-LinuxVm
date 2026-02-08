terraform {
  required_providers {
    
   azurerm = {

    source = "hashicorp/azurerm"
    version = "~> 3.0"

    }
    
  }
}

provider "azurerm" {
  features {
    
  }
}

resource "azurerm_resource_group" "VM-RG" {
  
  name = var.RG-Name
  location = var.RG-location
}


resource "azurerm_virtual_network" "VM-VNET" {

    name = var.VNET-Name
    resource_group_name = azurerm_resource_group.VM-RG.name
    location = azurerm_resource_group.VM-RG.location
    address_space = [ "172.16.0.0/16" ]
  
}


resource "azurerm_subnet" "VM-Subnet" {

    name = var.Subnet-Name
    virtual_network_name = azurerm_virtual_network.VM-VNET.name
    resource_group_name = azurerm_resource_group.VM-RG.name
    address_prefixes = [ "172.16.0.0/24" ]
  
}

resource "azurerm_network_interface" "VM-NIC" {

    name = var.NIC-Name
    resource_group_name = azurerm_resource_group.VM-RG.name
    location = azurerm_resource_group.VM-RG.location
   
    ip_configuration {

      name = "Internal"
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.VM-Subnet.id
      public_ip_address_id = azurerm_public_ip.VM-Public-IP.id
    }
  
}

resource "azurerm_public_ip" "VM-Public-IP" {

    name = var.Public-IP-Name
    resource_group_name = azurerm_resource_group.VM-RG.name
    location = azurerm_resource_group.VM-RG.location
    allocation_method = "Static"
    sku = "Standard"
 
}



resource "azurerm_network_security_group" "VM-NSG" {
  name                = var.NSG-Name
  location            = azurerm_resource_group.VM-RG.location
  resource_group_name = azurerm_resource_group.VM-RG.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

# Generate SSH key dynamically
resource "tls_private_key" "vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "VM-Name" {

    name = var.VM-Name
    resource_group_name = azurerm_resource_group.VM-RG.name
    location = azurerm_resource_group.VM-RG.location
    size = var.VM-Size #Standard_D2als_v7
    admin_username = var.admin_username #azureuser

    network_interface_ids = [ azurerm_network_interface.VM-NIC.id ]
    
    admin_ssh_key {
      username = "azureuser"
      public_key = tls_private_key.vm_ssh_key.public_key_openssh
    }
  
    os_disk {
      caching = "ReadWrite"
      disk_size_gb = var.Disk_Size #30
      storage_account_type = "Standard_LRS"
    }

    source_image_reference {
      publisher = "canonical"
      offer = "ubuntu-24_04-lts"
      sku = "server"
      version = "latest"
    
    

    }
}

# Optional: save private key locally (for login)
resource "local_file" "private_key" {
  content  = tls_private_key.vm_ssh_key.private_key_pem
  filename = "${path.module}/keys/vm_key.pem"
  file_permission = "0600"
}