# Configure the Microsoft Azure Provider
provider "azurerm" {
    version = "2.5"
    features {}
# Configure with details for your subscription. Account used should have Contributor role.
    subscription_id = ""
    client_id       = ""
    client_secret   = ""
    tenant_id       = ""
}

#Create network and NSG
# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "nios-network-rg"
    location = "centralus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create a virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "nios-vnet"
    address_space       = ["10.32.0.0/16"]
    location            = azurerm_resource_group.myterraformgroup.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create 2 subnets
resource "azurerm_subnet" "myterraformsubnet1" {
    name                 = "lan1"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.32.1.0/24"
}
resource "azurerm_subnet" "myterraformsubnet2" {
    name                 = "mgmt"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.32.2.0/24"
}

# Create Network Security Group and rules for Grid/DNS traffic
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "vniossg"
    location            = azurerm_resource_group.myterraformgroup.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name
}
resource "azurerm_network_security_rule" "ssh" {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name        = azurerm_resource_group.myterraformgroup.name
    network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}
resource "azurerm_network_security_rule" "dns1" {
    name                       = "DNS-UDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name        = azurerm_resource_group.myterraformgroup.name
    network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}
resource "azurerm_network_security_rule" "dns2" {
    name                       = "DNS-TCP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name        = azurerm_resource_group.myterraformgroup.name
    network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}
resource "azurerm_network_security_rule" "https" {
    name                       = "HTTPS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name        = azurerm_resource_group.myterraformgroup.name
    network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}
resource "azurerm_network_security_rule" "grid1" {
    name                       = "GRID1"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1194"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name        = azurerm_resource_group.myterraformgroup.name
    network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}
resource "azurerm_network_security_rule" "grid2" {
    name                       = "GRID2"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "2114"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name        = azurerm_resource_group.myterraformgroup.name
    network_security_group_name = azurerm_network_security_group.myterraformnsg.name
}


# Deploy vnios
# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myvniosgroup" {
    name     = "vnios-rg"
    location = "centralus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create public IP (optional)
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "nios-pubip1"
    location                     = azurerm_resource_group.myvniosgroup.location
    resource_group_name          = azurerm_resource_group.myvniosgroup.name
    allocation_method            = "Static"
    sku                          = "Standard"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interfaces
resource "azurerm_network_interface" "myterraformnic1" {
    name                      = "LAN1-NIC"
    location                     = azurerm_resource_group.myvniosgroup.location
    resource_group_name          = azurerm_resource_group.myvniosgroup.name

    ip_configuration {
        name                          = "myNicConfiguration1"
        subnet_id                     = azurerm_subnet.myterraformsubnet1.id
        primary                       = true
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "myterraformnic2" {
    name                      = "MGMT-NIC"
    location                     = azurerm_resource_group.myvniosgroup.location
    resource_group_name          = azurerm_resource_group.myvniosgroup.name

    ip_configuration {
        name                          = "myNicConfiguration2"
        subnet_id                     = azurerm_subnet.myterraformsubnet2.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interfaces
resource "azurerm_network_interface_security_group_association" "nic1" {
    network_interface_id      = azurerm_network_interface.myterraformnic1.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}
resource "azurerm_network_interface_security_group_association" "nic2" {
    network_interface_id      = azurerm_network_interface.myterraformnic2.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        resource_group = azurerm_resource_group.myvniosgroup.name
    }
    
    byte_length = 8
}
# Create storage account for disk
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "vnios${random_id.randomId.hex}"
    location                     = azurerm_resource_group.myvniosgroup.location
    resource_group_name          = azurerm_resource_group.myvniosgroup.name
    account_tier                = "Premium"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_storage_container" "con1" {
  name                  = "disks"
  storage_account_name  = azurerm_storage_account.mystorageaccount.name
  container_access_type = "private"
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount2" {
    name                        = "diag${random_id.randomId.hex}"
    location                     = azurerm_resource_group.myvniosgroup.location
    resource_group_name          = azurerm_resource_group.myvniosgroup.name
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "vnios-demovm"
    location                     = azurerm_resource_group.myvniosgroup.location
    resource_group_name          = azurerm_resource_group.myvniosgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic1.id,azurerm_network_interface.myterraformnic2.id]
    primary_network_interface_id = azurerm_network_interface.myterraformnic1.id
    vm_size                  = "Standard_DS11_v2"

    storage_os_disk {
        name              = "myosdisk1"
        caching           = "ReadWrite"
        vhd_uri           = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}${azurerm_storage_container.con1.name}/myosdisk1.vhd"
        create_option     = "FromImage"
    }
# Specifiy the NIOS reference image
    storage_image_reference {
        publisher = "infoblox"
        offer     = "infoblox-cp-v1405"
        sku       = "vsot"
        version   = "843.383835.0"
    }
# Specify the Azure marketplace item
    plan {
        name = "vsot"
        publisher = "infoblox"
        product = "infoblox-cp-v1405"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
    os_profile {
        computer_name  = "vnios-tf1"
        admin_username = "madmin"
        admin_password = "Infoblox_1"
        ## The custom_data column is required to pass the values to cloud-init script used by Infoblox 
        # remote_console_enabled - Enables console remote access  
        # default_admin_password - Enables CLI access to vnios instance
        # temp_license           - Enables temporary license for grid, dns and dhcp
        custom_data    = base64encode("remote_console_enabled: y\ndefault_admin_password: Infoblox_1\ntemp_license: dns dhcp grid")
  }

    boot_diagnostics {
        enabled     = true
        storage_uri = azurerm_storage_account.mystorageaccount2.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}