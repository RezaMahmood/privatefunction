# Apply security controls

#Associate NSG with subnets
# Cannot apply NSG to private endpoints at the moment - https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#known-issues
az network vnet subnet update -g $shared_network_rg --name $privateservices_subnet --vnet-name $network_name --network-security-group $lockdown_nsg
az network vnet subnet update -g $shared_network_rg --name $services_subnet --vnet-name $network_name --network-security-group $lockdown_nsg
az network vnet subnet update -g $shared_network_rg --name $function_subnet --vnet-name $network_name --network-security-group $lockdown_nsg

#Apply a service endpoint policy for storage

#We will also need to ensure that the storage account that Functions uses will still be accessible once we apply NSG's restricting outbound traffic
az storage account update --resource-group $app_rg --name $func_storage_name --default-action Deny
az storage account network-rule add -g $app_rg --account-name $func_storage_name --subnet $function_subnet_id --action allow
az storage account network-rule add -g $app_rg --account-name $func_storage_name  --subnet $services_subnet_id --action allow

az network service-endpoint policy create --resource-group $shared_network_rg --name storagepolicy --location $location

appstor_id=$(az storage account show -g $app_rg -n $func_storage_name --query 'id' -o tsv)
sharedstor_id=$(az storage account show -g $shared_rg -n $storage_name --query 'id' -o tsv)

az network service-endpoint policy-definition create --name storagepolicy_def -g $shared_network_rg --policy-name storagepolicy --service "Microsoft.Storage" --service-resources $appstor_id $sharedstor_id --description "Allow access to specific storage accounts"

#az network vnet subnet update --vnet-name $network_name -g $shared_network_rg --name $function_subnet --service-endpoints Microsoft.Storage --service-endpoint-policy storagepolicy
az network vnet subnet update --vnet-name $network_name -g $shared_network_rg --name $services_subnet --service-endpoints Microsoft.Storage --service-endpoint-policy storagepolicy