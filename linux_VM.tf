resource "azurerm_resource_group" "rg1" {
  location = "eastus"
  name     = "rg1_name"
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network1" {
  name                = "myVnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet1" {
  name                 = "mySubnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network1.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip1" {
  name                = "myPublicIP1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg1" {
  name                = "myNetworkSecurityGroup1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "SSH1"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic1" {
  name                = "myNIC1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "my_nic_configuration1"
    subnet_id                     = azurerm_subnet.my_terraform_subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip1.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example1" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic1.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg1.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm1" {
  name                  = "linuxVM"
  location              = azurerm_resource_group.rg1.location
  resource_group_name   = azurerm_resource_group.rg1.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic1.id]
  size                  = "Standard_DS1_v2"
  admin_username      	= "linuxusr"
  admin_password      	= "Azure123456!"
  disable_password_authentication = "false"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

}

output "public_ip" {
  value = azurerm_linux_virtual_machine.my_terraform_vm1.public_ip_address
}