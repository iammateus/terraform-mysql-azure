terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroupVM"
    location = "eastus"

    tags     = {
        "Environment" = "MySQL"
    }
}

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
}

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "myTFPublicIP"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "SSH"
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

resource "azurerm_network_interface" "nic" {
  name                      = "myNICVM2"
  location                  = "eastus"
  resource_group_name       = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "myNICConfg"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "myTFVM"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "myOsDiskmyTFVM"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "myTFVM"
    admin_username = "mateus"
    admin_password = "teteuS2"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "public_ip_address" {
  value = azurerm_public_ip.publicip.ip_address
}

resource "null_resource" "upload" {
    provisioner "file" {
        source      = "mysql"
        destination = "/tmp/mysql/"
        connection {
            type = "ssh"
            user = "mateus"
            password = "teteuS2"
            host = azurerm_public_ip.publicip.ip_address
        }
    }
}

resource "null_resource" "deploy" {
    triggers = {
        order = null_resource.upload.id
    }
    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "mateus"
            password = "teteuS2"
            host = azurerm_public_ip.publicip.ip_address
        }
        inline = [
            "sudo apt-get update",
            "echo 'mysql-server mysql-server/root_password password teteuS2' | sudo debconf-set-selections",
            "echo 'mysql-server mysql-server/root_password_again password teteuS2' | sudo debconf-set-selections",
            "sudo apt-get -y install mysql-server",
            "sudo chmod 777 /etc/mysql/mysql.conf.d/mysqld.cnf",
            "sudo cat /tmp/mysql/mysqld.cnf > /etc/mysql/mysql.conf.d/mysqld.cnf",
            "sudo service mysql restart",
            "mysql -u root -p'teteuS2' < /tmp/mysql/users.sql 2>/dev/null",
        ]
    }
}