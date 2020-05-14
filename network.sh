
az network vnet create -g $shared_network_rg -n $network_name --address-prefix 10.1.0.0/16 --subnet-name $services_subnet --subnet-prefix 10.1.0.0/27

az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n $privateservices_subnet --address-prefixes 10.1.1.0/27

az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n $function_subnet --address-prefixes 10.1.2.0/27

az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n "AzureBastionSubnet" --address-prefixes 10.1.3.0/27

#Create rules to estrict all outbound access from the vnet
az network nsg create --name $lockdown_nsg -g $shared_network_rg
az network nsg rule create --name allowdns --nsg-name $lockdown_nsg -g $shared_network_rg --priority 200 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet --destination-port-ranges 53 --protocol '*' --description "Allow DNS queries"
az network nsg rule create --name allowVnet --nsg-name $lockdown_nsg -g $shared_network_rg --priority 210 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefix VirtualNetwork --destination-port-ranges '*' --protocol '*' --description "Allow inter Vnet traffic"
az network nsg rule create --name blockoutrule --nsg-name $lockdown_nsg -g $shared_network_rg --priority 300 --direction Outbound --access Deny --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet --destination-port-ranges '*' --protocol '*' --description "Block all outbound traffic origination from vnet"

# Create rules to restrict all inbound access from the vnet
az network nsg rule create --name blockinrule --nsg-name $lockdown_nsg -g $shared_network_rg --priority 100 --direction Inbound --access Deny --source-address-prefixes Internet --destination-port-ranges '*' --protocol '*' --description "Block all inbound traffic"

# Create a DNS server - no longer required - will repurpose to jump/test box
vm_dns_obj=$(az vm create -g $shared_network_rg -n $vm_dns --image Win2016Datacenter --admin-username $vm_dns_username --vnet-name $network_name --subnet $services_subnet --public-ip-address "" --private-ip-address $vm_dns_privateip --authentication-type password --admin-password $vm_dns_adminpassword --size Standard_B2ms )

# Create a Bastion
az network public-ip create -n BastionPIP -g $shared_network_rg --sku Standard
az network bastion create -n MyBastion --public-ip-address BastionPIP -g $shared_network_rg --vnet-name $network_name --location $location

# Reference new VM as the DNS server for the vnet - no longer needed as app service can now use private zones (configured later)
# az network vnet update -g $shared_network_rg -n $network_name --dns-servers $vm_dns_privateip