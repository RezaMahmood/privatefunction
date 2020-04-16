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

#Note to self: precedence appears to be important
#Need to disable subnet private endpoint policy
az network vnet subnet update -g $shared_network_rg --vnet-name $network_name -n $privateservices_subnet --disable-private-endpoint-network-policies true
# Create private endpoint for the queue endpoint of the shared storage account
az network private-endpoint create --name ${storage_name}-pe --connection-name ${storage_name}-queue-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $storage_id --group-ids queue
# Create private DNS zone for the private queue endpoint
az network private-dns zone create -g $shared_network_rg -n "privatelink.queue.core.windows.net"
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.queue.core.windows.net" --name sharedqueuednslink --virtual-network $network_name --registration-enabled false

#Query for the network interface ID created as part of private endpoint
storage_networkInterfaceId=$(az network private-endpoint show --name ${storage_name}-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
storage_nic_object=$(az resource show --ids $storage_networkInterfaceId --api-version 2019-04-01 -o json)
# Get the content for privateIPAddress and FQDN matching the SQL server name - this needs to have jq installed - https://stedolan.github.io/jq/
storage_nic_ip=$(echo $storage_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')

#Create DNS records 
az network private-dns record-set a create --name $storage_name --zone-name "privatelink.queue.core.windows.net" --resource-group $shared_network_rg  
az network private-dns record-set a add-record --record-set-name $storage_name --zone-name "privatelink.queue.core.windows.net" --resource-group $shared_network_rg -a $storage_nic_ip

# Create the storage account that the Function should not have access to
az storage account create --name $noaccess_storage_name --resource-group $shared_rg --location $location --access-tier $noaccess_storage_access_tier --sku $noaccess_storage_sku --kind $noaccess_storage_kind
noaccess_storage_key=$(az storage account keys list --account-name $noaccess_storage_name --query '[0]'.value -o tsv)
az storage container create --name $noaccess_storage_container --account-name $noaccess_storage_name --account-key $noaccess_storage_key --auth-mode key
# Upload a file that should not be accessible from the Function if the Function has the correct access key to it
noaccess_storage_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $noaccess_storage_name --query connectionString -o tsv)
az storage blob upload --account-name $noaccess_storage_name -f $noaccess_storage_file -c $noaccess_storage_container -n $noaccess_storage_file --connection-string $noaccess_storage_connectionstring

#CosmosDB
cosmosdb_object=$(az cosmosdb create -n $cosmosdb_account_name -g $shared_rg --locations regionName=$location)
cosmosdb_account_id=$(echo $cosmosdb_object | jq -rc '.id')
az cosmosdb sql database create -a $cosmosdb_account_name -g $shared_rg -n $cosmosdb_database_name
az cosmosdb sql container create -a $cosmosdb_account_name -g $shared_rg -n $cosmosdb_container_name -p '/id' --throughput 400 -d $cosmosdb_database_name
# Create private endpoint for CosmosDB
az network private-endpoint create --name ${cosmosdb_account_name}-pe --connection-name ${cosmosdb_account_name}-sql-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $cosmosdb_account_id --group-ids Sql
# Create private DNS zone for the private cosmosdb endpoint
az network private-dns zone create -g $shared_network_rg -n "privatelink.documents.azure.com"
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.documents.azure.com" --name sharedcosmosdnslink --virtual-network $network_name --registration-enabled false

#Query for the network interface ID created as part of private endpoint
cosmosdb_networkInterfaceId=$(az network private-endpoint show --name ${cosmosdb_account_name}-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
cosmosdb_nic_object=$(az resource show --ids $cosmosdb_networkInterfaceId --api-version 2019-04-01 -o json)
# Get the content for privateIPAddress and FQDN matching the SQL server name - this needs to have jq installed - https://stedolan.github.io/jq/
cosmosdb_nic_ip=$(echo $cosmosdb_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')

#Create DNS records 
az network private-dns record-set a create --name $cosmosdb_account_name --zone-name "privatelink.documents.azure.com" --resource-group $shared_network_rg  
az network private-dns record-set a add-record --record-set-name $storage_name --zone-name "privatelink.documents.azure.com" --resource-group $shared_network_rg -a $cosmosdb_nic_ip



# Create an Event Hub as a sink for blob file records - #TODO: This needs to change to Event Hub Dedicate to use with Private Link
az eventhubs namespace create --name $eventhub_namespace -g $shared_rg --sku Basic --location $location
az eventhubs eventhub create --name $eventhub_name -g $shared_rg --namespace-name $eventhub_namespace --message-retention 1
# Create a Send policy
az eventhubs eventhub authorization-rule create --eventhub-name $eventhub_name --name Send -g $shared_rg --namespace-name $eventhub_namespace --rights Send


# Create Key Vault
keyvault_object=$(az keyvault create -n $keyvault_name -g $shared_rg --location $location)
az keyvault secret set --vault-name $keyvault_name --name $keyvault_secret_name --value $keyvault_secret_value
# Set private link for key vault

