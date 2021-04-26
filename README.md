# terraform-mysql-azure

A Terraform project that deploys a MySQL virtual machine in Microsoft Azure.

## Requeriments

1. [Terraform](https://www.terraform.io/).
2. [Azure Account](https://azure.microsoft.com/en-us/).
3. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

## Installation

Use the Azure CLI to authenticate to Microsoft Azure.

    $ terraform apply
    
## How to connect externally

    $ mysql -h 127.0.0.1 -P 3306 -u {USER} -p 

## MySQL users

| User | Password | Connectivity |
|--|--|--|
| root| AstrongP4ss | local |
| mateus| mateus | local and external |

## License

[MIT](https://github.com/iammateus/terraform-mysql-azure/blob/main/LICENSE)
