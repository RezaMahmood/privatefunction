# Apply security controls

#Associate NSG with subnets
# Cannot apply NSG to subnet hosting private endpoints at the moment - https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#known-issues - this should be ok as we are applying the rule on the functions subnet as well
az network vnet subnet update -g $shared_network_rg --name $privateservices_subnet --vnet-name $network_name --network-security-group $lockdown_nsg
az network vnet subnet update -g $shared_network_rg --name $services_subnet --vnet-name $network_name --network-security-group $lockdown_nsg
az network vnet subnet update -g $shared_network_rg --name $function_subnet --vnet-name $network_name --network-security-group $lockdown_nsg



