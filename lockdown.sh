# Apply security controls

#Associate NSG with subnets
az network vnet subnet update -g $shared_network_rg --name $privateservices_subnet --vnet-name $network_name --network-security-group Lockdown
az network vnet subnet update -g $shared_network_rg --name $services_subnet --vnet-name $network_name --network-security-group Lockdown
az network vnet subnet update -g $shared_network_rg --name $function_subnet --vnet-name $network_name --network-security-group Lockdown

# Set firewall on shared storage account to deny public access
az storage account update --resource-group $shared_rg --name $storage_name --default-action Deny
function_subnet_id=$(az network vnet subnet show -g $shared_network_rg -n $function_subnet --vnet-name $network_name --query 'id' -o tsv)


az network vnet subnet update --vnet-name $network_name -g $shared_network_rg --service-endpoints Microsoft.Storage --name $function_subnet

az storage account network-rule add -g $shared_rg --account-name $storage_name  --subnet $function_subnet_id --action allow

az keyvault update --name $keyvault_name --resource-group $shared_rg --default-action deny
# Only allow access to keyvault from FunctionApp subnet
az keyvault network-rule --name $keyvault_name --ip-address 10.1.2.0/27 -g $shared_rg