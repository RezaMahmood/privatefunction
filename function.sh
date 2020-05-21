#Separate Storage account for Functions backing store
func_storage_object=$(az storage account create --name $func_storage_name --resource-group $app_rg --location $location --access-tier $func_storage_access_tier --sku $func_storage_sku --kind $func_storage_kind)
func_storage_id=$(echo $func_storage_object | jq -rc '.id')

az functionapp plan create --name $functionapp_plan -g $app_rg --location $location --sku EP1

az functionapp create --name $functionapp_name --resource-group $app_rg --storage-account $func_storage_name --functions-version 3 --os-type Linux --runtime dotnet --plan $functionapp_plan

#Configure vnet integration
az functionapp vnet-integration add -g $app_rg --name $functionapp_name --vnet $network_name --subnet $function_subnet

#Configure application settings
cosmos_connectionstring=$(az cosmosdb keys list --name $cosmosdb_account_name -g $shared_rg --type connection-strings --query 'connectionStrings[0].connectionString' -o tsv)
sharedstor_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $storage_name --query connectionString -o tsv)
eventhub_connectionstring=$(az eventhubs eventhub authorization-rule keys list -g $shared_rg --namespace-name $eventhub_namespace --eventhub-name $eventhub_name -n Send --query primaryConnectionString -o tsv)
noaccessstor_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $noaccess_storage_name --query connectionString -o tsv)

az functionapp config appsettings set -n $functionapp_name -g $app_rg --settings "CosmosDBConnection"=$cosmos_connectionstring "SharedStor"=$sharedstor_connectionstring "EventHubConnection"=$eventhub_connectionstring "EventHubName"="rezasharedhub" WEBSITE_VNET_ROUTE_ALL=1 "GetUrls=https://www.microsoft.com/;https://www.google.com/;https://www.dropbox.com/" "Blob.Path=$noaccess_storage_container/$noaccess_storage_file" WEBSITE_DNS_SERVER=$vm_jump_privateip "Blob1.StorageConnectionString"=$noaccessstor_connectionstring

#Enable virtual network trigger support - https://docs.microsoft.com/en-gb/azure/azure-functions/functions-networking-options#virtual-network-triggers-non-http
az resource update -g $app_rg -n $functionapp_name/config/web --set properties.functionsRuntimeScaleMonitoringEnabled=1 --resource-type Microsoft.Web/sites


#However, function app appears to be able to understand private endpoints
# Create private endpoint for the queue endpoint of the shared storage account
az network private-endpoint create --name ${func_storage_name}-file-pe --connection-name ${func_storage_name}-file-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $func_storage_id --group-ids file
# Create private endpoint for the blob endpoint of the shared storage account
az network private-endpoint create --name ${func_storage_name}-blob-pe --connection-name ${func_storage_name}-blob-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $func_storage_id --group-ids blob
# Create private endpoint for the table endpoint of the shared storage account
az network private-endpoint create --name ${func_storage_name}-table-pe --connection-name ${func_storage_name}-table-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $func_storage_id --group-ids table

#Create DNS records for blob, file and table endpoints
func_storage_file_nic_id=$(az network private-endpoint show --name ${func_storage_name}-file-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
func_storage_blob_nic_id=$(az network private-endpoint show --name ${func_storage_name}-blob-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
func_storage_table_nic_id=$(az network private-endpoint show --name ${func_storage_name}-table-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)

func_storage_file_nic_object=$(az resource show --ids $func_storage_file_nic_id --api-version 2019-04-01 -o json)
func_storage_blob_nic_object=$(az resource show --ids $func_storage_blob_nic_id --api-version 2019-04-01 -o json)
func_storage_table_nic_object=$(az resource show --ids $func_storage_table_nic_id --api-version 2019-04-01 -o json)

func_storage_file_nic_ip=$(echo $func_storage_file_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')
func_storage_blob_nic_ip=$(echo $func_storage_blob_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')
func_storage_table_nic_ip=$(echo $func_storage_table_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')

az network private-dns record-set a create --name $func_storage_name --zone-name "privatelink.file.core.windows.net" --resource-group $shared_network_rg  
az network private-dns record-set a create --name $func_storage_name --zone-name "privatelink.table.core.windows.net" --resource-group $shared_network_rg  
az network private-dns record-set a create --name $func_storage_name --zone-name "privatelink.blob.core.windows.net" --resource-group $shared_network_rg  

az network private-dns record-set a add-record --record-set-name $func_storage_name --zone-name "privatelink.blob.core.windows.net" --resource-group $shared_network_rg -a $func_storage_blob_nic_ip
az network private-dns record-set a add-record --record-set-name $func_storage_name --zone-name "privatelink.file.core.windows.net" --resource-group $shared_network_rg -a $func_storage_file_nic_ip
az network private-dns record-set a add-record --record-set-name $func_storage_name --zone-name "privatelink.table.core.windows.net" --resource-group $shared_network_rg -a $func_storage_table_nic_ip

