# Introduction 

The scripts in this repo are intended to deploy Azure Functions to demonstrate network isolation when communicating with other Azure PaaS services.  Note that this deployment does not represent a best practice way of creating Azure resources and is mainly intended to demonstrate the principles behind locking down Azure PaaS services and applying network isolation.

[Note: at this time, although the scripts deploy Azure Key Vault, none of the Functions deployed (in the Application folder) make use of it.  The function using Azure Event Hub works but not through Private Endpoint as Private Endpoint is only available on the Dedicated SKU for Azure Event Hub]

## Architecture

The scripts in this repo will provision:

- Premium Function App with Virtual Network integration
- Virtual Network for services to integrate with
- Storage Accounts
- CosmosDB Account
- Azure Event Hub
- Azure Key Vault
- Azure Firewall
- Private Endpoints and associated DNS entries

![Azure Function connecting to Private Endpoints](https://github.com/RezaMahmood/privatefunction/blob/master/PrivateFunction.gif)

## Getting Started

1. Installation Process

- Install jq to enable json parsing - https://stedolan.github.io/jq/

- Edit variables.sh to set environment variables.  Note that some variables are globally unique such as storage account names.
  
- From a bash shell

  - az login

  - source deploy_infra.sh

  - (Wait about an hour to deploy all resources)

- Deploy the application to the Function App you have just created!

- Set up the Jump Box

  - [Connect to Jump Box using Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/bastion-connect-vm-rdp)

  - [Install Azure Storage Explorer](https://azure.microsoft.com/en-gb/features/storage-explorer/)

  - [Install DNS Server](https://www.hostwinds.com/guide/setup-configure-dns-windows-server/)

  - Configure DNS forwarder to use address: [168.63.129.16](https://docs.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16)

## Testing

### PrivateCosmosFunction

This function implements a storage queue trigger.  For each queue it finds, it will generate a random ID and then store to CosmosDB.  Test this out by placing one or more messages on the queue and watching them appear in the CosmosDB container.  To check that the FunctionApp is using Private Endpoints, open up a Kudu command shell on the Function App and type:

- nameresolver [sharedstorageaccountname].queue.core.windows.net
  - this should resolve to a non-routable local IP address like 10.1.1.4 and display a CNAME to [sharedstorageaccountname].privatelink.queue.core.windows.net
- nameresolver [cosmosdbaccountname].documents.azure.com
  - this should resolve to a non-routable local IP address like 10.1.1.5 and display a CNAME to [cosmosdbaccountname].privatelink.documents.azure.com

### PrivateFilesFunction

This function implements a blob trigger.  For each file it finds, it will parse the file and create a batch of events to send to EventHub.  Test this out by placing a file into a container called "sharedcontainer", ensuring it has multiple lines of text in it.  Messages should appear in EventHub, one per line in the file.

### DeniedOutboundCalls

This function implements a HTTP trigger (GET).  When executed (e.g. with Postman), the function will attempt to:

- make a HTTP request to: www.google.com, www.microsoft.com, www.dropbox.com (configurable in App Configuration)

- connect to a storage account and read a file (simulating a malicious payload)

If Azure Firewall and Route tables have been configured correctly, this Function should return JSON indicating a failure to connect to resources.  Altering AFW rules or removing the route table will show succesful connectivty to the URL's and/or access to the storage account.

## Description of scripts

### variables.sh

This file contains variables required to deploy the environment and is used by subsequent cli scripts.  This file should be edited to use unique Azure resource names.  

### resourcegroups.sh

Creates the resource groups needed for the environment

### network.sh

This file contains all the base network configurations including NSG and subnet configurations. Network resources are separated to cater for RBAC scenarios

App Service does support Azure Private DNS Zones and requires an update to the configuration to set WEBSITE_DNS_SERVER=168.63.129.16, however, this wasn't working reliably at the time of creating these scripts so we will install a DNS server and configure that to forward to Azure DNS to resolve private endpoints.

### shared.sh

This file contains all the shared resources that the application will use such as Storage, Event Hubs and CosmosDB Accounts.

### function.sh

This file contains configuration for the Function App that will be network isolated.  This needs to be run last as it will use variables from resources created previously such as CosmosDB and Storage Account connection strings.

### monitoring.sh

This script will set up monitoring resources to allow logging of network traffic

### cleanup.sh

Deletes all the resource groups that are deployed (and all child resources)
