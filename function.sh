#Separate Storage account for Functions backing store
func_storage_object=$(az storage account create --name $func_storage_name --resource-group $app_rg --location $location --access-tier $func_storage_access_tier --sku $func_storage_sku --kind $func_storage_kind)
func_storage_id=$(echo $func_storage_object | jq -rc '.id')

webjob_storage_object=$(az storage account create --name $funcjob_storage_name --resource-group $app_rg --location $location --access-tier $func_storage_access_tier --sku $func_storage_sku --kind $func_storage_kind)
webjob_storage_id=$(echo $webjob_storage_object | jq -rc '.id')

az functionapp plan create --name $functionapp_plan -g $app_rg --location $location --sku EP1

az functionapp create --name $functionapp_name --resource-group $app_rg --storage-account $func_storage_name --functions-version 3 --os-type Linux --runtime dotnet --plan $functionapp_plan

#Configure vnet integration
az functionapp vnet-integration add -g $app_rg --name $functionapp_name --vnet $network_name --subnet $function_subnet

#Configure application settings
cosmos_connectionstring=$(az cosmosdb keys list --name $cosmosdb_account_name -g $shared_rg --type connection-strings --query 'connectionStrings[0].connectionString' -o tsv)
sharedstor_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $storage_name --query connectionString -o tsv)
eventhub_connectionstring=$(az eventhubs eventhub authorization-rule keys list -g $shared_rg --namespace-name $eventhub_namespace --eventhub-name $eventhub_name -n Send --query primaryConnectionString -o tsv)
noaccessstor_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $noaccess_storage_name --query connectionString -o tsv)
webjob_storage_connectionstring=$(az storage account show-connection-string -g $app_rg -n $funcjob_storage_name --query connectionString -o tsv)

az functionapp config appsettings set -n $functionapp_name -g $app_rg --settings "CosmosDBConnection"=$cosmos_connectionstring "SharedStor"=$sharedstor_connectionstring "EventHubConnection"=$eventhub_connectionstring "EventHubName"="rezasharedhub" WEBSITE_VNET_ROUTE_ALL=1 "GetUrls=https://www.microsoft.com/;https://www.google.com/;https://www.dropbox.com/" "Blob.Path=$noaccess_storage_container/$noaccess_storage_file" WEBSITE_DNS_SERVER=10.1.0.4 "Blob1.StorageConnectionString"=$noaccessstor_connectionstring "AzureWebJobsStorage"=$webjob_storage_connectionstring

#Enable virtual network trigger support - https://docs.microsoft.com/en-gb/azure/azure-functions/functions-networking-options#virtual-network-triggers-non-http
az resource update -g $app_rg -n $functionapp_name/config/web --set properties.functionsRuntimeScaleMonitoringEnabled=1 --resource-type Microsoft.Web/sites

