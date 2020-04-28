# Apply security controls

#Associate NSG with subnets
az network vnet subnet update -g $shared_network_rg --name $privateservices_subnet --vnet-name $network_name --network-security-group Lockdown
az network vnet subnet update -g $shared_network_rg --name $services_subnet --vnet-name $network_name --network-security-group Lockdown
az network vnet subnet update -g $shared_network_rg --name $function_subnet --vnet-name $network_name --network-security-group Lockdown

# Set firewall on shared storage account to deny public access
az storage account update --resource-group $shared_rg --name $storage_name --default-action Deny

