# Apply security controls

#Associate NSG with subnets
# Cannot apply NSG to private endpoints at the moment - https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#known-issues
az network vnet subnet update -g $shared_network_rg --name $privateservices_subnet --vnet-name $network_name --network-security-group $lockdown_nsg
az network vnet subnet update -g $shared_network_rg --name $services_subnet --vnet-name $network_name --network-security-group $lockdown_nsg
az network vnet subnet update -g $shared_network_rg --name $function_subnet --vnet-name $network_name --network-security-group $lockdown_nsg


#We will also need to ensure that the storage account that Functions uses will still be accessible once we apply NSG's restricting outbound traffic

#az storage account update --resource-group $app_rg --name $funcjob_storage_name --default-action Deny
#az storage account network-rule add -g $app_rg --account-name $funcjob_storage_name --subnet $function_subnet_id --action allow
#az storage account network-rule add -g $app_rg --account-name $funcjob_storage_name  --subnet $services_subnet_id --action allow
