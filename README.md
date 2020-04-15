# Introduction 

The scripts in this repo are intended to deploy Azure Functions to demonstrate network isolation when communicating with other Azure PaaS services.

## Getting Started

1. Installation Process

- Go and install jq to enable json parsing - https://stedolan.github.io/jq/

- Edit base.azcli to set environment variables.  Note that some variables are globally unique such as storage account names.
  
- Run scripts in the following order:

  - base.azcli

  - network.azcli

  - shared.azcli

  - function.azcli

  - lockdown.azcli

## Description of scripts

### base.azcli

This file contains variables required to deploy the environment and is used by subsequent cli scripts.  This file should be edited to use unique Azure resource names.  In addition, 3 resource groups are created to host network, shared resources and application specific resources.  This script will also log you in to Azure and set the subscription that the resources will be deployed to - you will need to remove "az login" if you wish to use a pipeline for non-interactive deployment and edit the subscription Id to reference your own subscription.

### network.azcli

This file contains all the base network configurations including NSG and subnet configurations.

### shared.azcli

This file contains all the shared resources that the application will use such as Storage, Event Hubs and CosmosDB Accounts.

App Service does not support Azure Private DNS Zones yet, so we will need to install a DNS server and configure that to use the Private Link address.

### function.azcli

This file contains configuration for the Function App that will be network isolated.  This needs to be run last as it will use variables from resources created previously such as CosmosDB and Storage Account connection strings.

### lockdown.azcli

This file applies NSG to the subnets to prevent Function App from going beyond the vnet

## TO DO

Set up Linux DNS server using bind9 and setting forwarder to use 168.63.129.16 to resolve privatelink CNames