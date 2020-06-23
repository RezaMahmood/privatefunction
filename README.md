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

- Edit base.sh to set environment variables.  Note that some variables are globally unique such as storage account names.
  
- Run scripts in the following order (or run deploy_infra.sh):

  - base.sh

  - resourcegroups.sh

  - network.sh

  - shared.sh

  - function.sh

  - monitoring.sh

- Deploy the application to the Function App you have just created!

- Set up the Jump Box

  - Install Azure Storage Explorer

## Testing the lockdown

### PrivateCosmosFunction

This function uses a storage queue trigger.  For each queue it finds, it will generate a random ID and then store to CosmosDB.  Test this out by placing one or more messages on the queue and watching them appear in the CosmosDB container.  To check that the FunctionApp is using Private Endpoints, open up a Kudu command shell on the Function App and type:

- nameresolver [sharedstorageaccountname].queue.core.windows.net
  - this should resolve to a non-routable local IP address like 10.1.1.4 and display a CNAME to [sharedstorageaccountname].privatelink.queue.core.windows.net
- nameresolver [cosmosdbaccountname].documents.azure.com
  - this should resolve to a non-routable local IP address like 10.1.1.5 and display a CNAME to [cosmosdbaccountname].privatelink.documents.azure.com

### PrivateFilesFunction

This function uses a blob trigger.  For each file it finds, it will parse the file and create a batch of events to send to EventHub.  Test this out by placing a file into a container called "sharedcontainer", ensuring it has multiple lines of text in it.  Messages should appear in EventHub, one per line in the file.

## Description of scripts

### base.sh

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