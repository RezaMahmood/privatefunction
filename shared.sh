# Create the basic shared resources needed for the application
# CosmosDB
# Storage Account (for Storage queues)
# Service Bus
# Event Hub
# Key Vault


#Storage Account
storage_object=$(az storage account create --name $storage_name --resource-group $shared_rg --location $location --access-tier $storage_access_tier --sku $storage_sku --kind $storage_kind)
storage_id=$(echo $storage_object | jq -rc '.id')
storage_key=$(az storage account keys list --account-name $storage_name --query '[0]'.value -o tsv)

# Create a queue to test initial simple case of reading off queue to store into CosmosDB
az storage queue create --name $storage_queue --account-name $storage_name --account-key $storage_key --auth-mode key

# Create a blob container to simulate a file landing
az storage container create --name $storage_container --account-name $storage_name --account-key $storage_key --auth-mode key

# Create private endpoint for the queue endpoint of the shared storage account
az network private-endpoint create --name ${storage_name}-queue-pe --connection-name ${storage_name}-queue-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $storage_id --group-ids queue
# Create private endpoint for the blob endpoint of the shared storage account
az network private-endpoint create --name ${storage_name}-blob-pe --connection-name ${storage_name}-blob-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $storage_id --group-ids blob

#Query for the network interface ID created as part of private queue endpoint
storage_q_networkInterfaceId=$(az network private-endpoint show --name ${storage_name}-queue-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
storage_q_nic_object=$(az resource show --ids $storage_q_networkInterfaceId --api-version 2019-04-01 -o json)
# Get the content for privateIPAddress and FQDN matching the SQL server name - this needs to have jq installed - https://stedolan.github.io/jq/
storage_q_nic_ip=$(echo $storage_q_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')

#Create DNS records for queue endpoint
az network private-dns record-set a create --name $storage_name --zone-name "privatelink.queue.core.windows.net" --resource-group $shared_network_rg  
echo "Creating Private DNS A Record for privatelink.queue.core.windows.net"
az network private-dns record-set a add-record --record-set-name $storage_name --zone-name "privatelink.queue.core.windows.net" --resource-group $shared_network_rg -a $storage_q_nic_ip

#Query for the network interface ID created as part of private blob endpoint
storage_b_networkInterfaceId=$(az network private-endpoint show --name ${storage_name}-blob-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
storage_b_nic_object=$(az resource show --ids $storage_b_networkInterfaceId --api-version 2019-04-01 -o json)
# Get the content for privateIPAddress and FQDN matching the SQL server name - this needs to have jq installed - https://stedolan.github.io/jq/
storage_b_nic_ip=$(echo $storage_b_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')

#Create DNS records for blob endpoint
az network private-dns record-set a create --name $storage_name --zone-name "privatelink.blob.core.windows.net" --resource-group $shared_network_rg  
echo "Creating Private DNS A Record for privatelink.blob.core.windows.net"
az network private-dns record-set a add-record --record-set-name $storage_name --zone-name "privatelink.blob.core.windows.net" --resource-group $shared_network_rg -a $storage_b_nic_ip


# Create the storage account that the Function should not have access to
az storage account create --name $noaccess_storage_name --resource-group $shared_rg --location $location --access-tier $noaccess_storage_access_tier --sku $noaccess_storage_sku --kind $noaccess_storage_kind
noaccess_storage_key=$(az storage account keys list --account-name $noaccess_storage_name --query '[0]'.value -o tsv)
az storage container create --name $noaccess_storage_container --account-name $noaccess_storage_name --account-key $noaccess_storage_key --auth-mode key
# Upload a file that should not be accessible from the Function if the Function has the correct access key to it
noaccess_storage_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $noaccess_storage_name --query connectionString -o tsv)
az storage blob upload --account-name $noaccess_storage_name -f $noaccess_storage_file -c $noaccess_storage_container -n $noaccess_storage_file --connection-string $noaccess_storage_connectionstring

#CosmosDB. Note for purpose of this POC, we will allow access from the functions subnet and the services subnet (where the jump/test box sits)
cosmosdb_object=$(az cosmosdb create -n $cosmosdb_account_name -g $shared_rg --locations regionName=$location --enable-virtual-network true --ip-range-filter 10.1.0.0/27)
cosmosdb_account_id=$(echo $cosmosdb_object | jq -rc '.id')
az cosmosdb sql database create -a $cosmosdb_account_name -g $shared_rg -n $cosmosdb_database_name
az cosmosdb sql container create -a $cosmosdb_account_name -g $shared_rg -n $cosmosdb_container_name -p '/id' --throughput 400 -d $cosmosdb_database_name
# Create private endpoint for CosmosDB
az network private-endpoint create --name ${cosmosdb_account_name}-pe --connection-name ${cosmosdb_account_name}-sql-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $cosmosdb_account_id --group-ids Sql

#Query for the network interface ID created as part of private endpoint
cosmosdb_networkInterfaceId=$(az network private-endpoint show --name ${cosmosdb_account_name}-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
cosmosdb_nic_object=$(az resource show --ids $cosmosdb_networkInterfaceId --api-version 2019-04-01 -o json)
# Get the content for privateIPAddress and FQDN matching the SQL server name - this needs to have jq installed - https://stedolan.github.io/jq/
cosmosdb_nic_ip=$(echo $cosmosdb_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')
cosmosdb_regional_nic_ip=$(echo $cosmosdb_nic_object | jq -rc '.properties.ipConfigurations[1].properties.privateIPAddress')

#Create DNS records 
az network private-dns record-set a create --name $cosmosdb_account_name --zone-name "privatelink.documents.azure.com" --resource-group $shared_network_rg  
echo "Creating Private DNS A Record for privatelink.documents.azure.com"
az network private-dns record-set a add-record --record-set-name $cosmosdb_account_name --zone-name "privatelink.documents.azure.com" --resource-group $shared_network_rg -a $cosmosdb_nic_ip
az network private-dns record-set a add-record --record-set-name $cosmosdb_account_name-$location --zone-name "privatelink.documents.azure.com" --resource-group $shared_network_rg -a $cosmosdb_regional_nic_ip



# Create an Event Hub as a sink for blob file records - #TODO: This needs to change to Event Hub Dedicate to use with Private Link
az eventhubs namespace create --name $eventhub_namespace -g $shared_rg --sku Basic --location $location
az eventhubs eventhub create --name $eventhub_name -g $shared_rg --namespace-name $eventhub_namespace --message-retention 1
# Create a Send policy
az eventhubs eventhub authorization-rule create --eventhub-name $eventhub_name --name Send -g $shared_rg --namespace-name $eventhub_namespace --rights Send



# Create Key Vault - disable soft delete to avoid having to change keyvault name for POC - not recommended for Production
keyvault_object=$(az keyvault create -n $keyvault_name -g $shared_rg --location $location --enable-soft-delete false)
az keyvault secret set --vault-name $keyvault_name --name $keyvault_secret_name --value $keyvault_secret_value
keyvault_id=$(echo $keyvault_object | jq -rc '.id')
# Set private link for key vault
az network private-endpoint create --name ${keyvault_name}-pe --connection-name ${keyvault_name}-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $keyvault_id --group-ids vault

#Query for the NIC of the vault private endpoint
keyvault_networkInterfaceId=$(az network private-endpoint show --name ${keyvault_name}-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
keyvault_nic_object=$(az resource show --ids $keyvault_networkInterfaceId --api-version 2019-04-01 -o json)
keyvault_nic_ip=$(echo $keyvault_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')
#Create DNS records for keyvault private link
az network private-dns record-set a create --name $keyvault_name --zone-name "privatelink.vaultcore.azure.net" --resource-group $shared_network_rg
echo "Creating Private DNS A Record for privatelink.vaultcore.azure.net"
az network private-dns record-set a add-record --record-set-name $keyvault_name --zone-name "privatelink.vaultcore.azure.net" --resource-group $shared_network_rg -a $keyvault_nic_ip


# Create Service Endpoints for all services that need to be accessed via private endpoint - this is to force Function App to use private IP. Also need to do this for the jumpbox VM for testing
#az network vnet subnet update --vnet-name $network_name -g $shared_network_rg --service-endpoints Microsoft.Storage Microsoft.AzureCosmosDB Microsoft.KeyVault --name $function_subnet
az network vnet subnet update --vnet-name $network_name -g $shared_network_rg --service-endpoints Microsoft.Storage Microsoft.AzureCosmosDB --name $services_subnet
function_subnet_id=$(az network vnet subnet show -g $shared_network_rg -n $function_subnet --vnet-name $network_name --query 'id' -o tsv)
services_subnet_id=$(az network vnet subnet show -g $shared_network_rg -n $services_subnet --vnet-name $network_name --query 'id' -o tsv)

# Set vnet restrictions on cosmos and storage
az cosmosdb network-rule add -g $shared_rg --name $cosmosdb_account_name --subnet $function_subnet_id -g $shared_rg --vnet-name $network_name
az cosmosdb network-rule add -g $shared_rg --name $cosmosdb_account_name --subnet $services_subnet_id -g $shared_rg --vnet-name $network_name

# Set firewall on shared storage account to deny public access
az storage account update --resource-group $shared_rg --name $storage_name --default-action Deny
az storage account network-rule add -g $shared_rg --account-name $storage_name  --subnet $function_subnet_id --action allow
az storage account network-rule add -g $shared_rg --account-name $storage_name  --subnet $services_subnet_id --action allow


az keyvault update --name $keyvault_name --resource-group $shared_rg --default-action deny
# Only allow access to keyvault from FunctionApp subnet
az keyvault network-rule add --name $keyvault_name -g $shared_rg --subnet $function_subnet_id --vnet-name $network_name