
az network vnet create -g $shared_network_rg -n $network_name --address-prefix 10.1.0.0/16 --subnet-name $services_subnet --subnet-prefix 10.1.0.0/27
az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n $privateservices_subnet --address-prefixes 10.1.1.0/27
az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n $function_subnet --address-prefixes 10.1.2.0/27
az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n "AzureBastionSubnet" --address-prefixes 10.1.3.0/27

#Create rules to estrict all outbound access from the vnet
az network nsg create --name $lockdown_nsg -g $shared_network_rg
az network nsg rule create --name allowdns --nsg-name $lockdown_nsg -g $shared_network_rg --priority 200 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet --destination-port-ranges 53 --protocol '*' --description "Allow DNS queries"
az network nsg rule create --name allowVnet --nsg-name $lockdown_nsg -g $shared_network_rg --priority 210 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefix VirtualNetwork --destination-port-ranges '*' --protocol '*' --description "Allow inter Vnet traffic"
# Note that this could be scoped further to a specific region's storage accounts
az network nsg rule create --name allowstorage --nsg-name $lockdown_nsg -g $shared_network_rg --priority 220 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefix Storage --destination-port-ranges '*' --protocol '*' --description "Allow traffic to all storage accounts"
az network nsg rule create --name blockoutrule --nsg-name $lockdown_nsg -g $shared_network_rg --priority 300 --direction Outbound --access Deny --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet --destination-port-ranges '*' --protocol '*' --description "Block all outbound traffic origination from vnet"

# Create rules to restrict all inbound access from the vnet
az network nsg rule create --name blockinrule --nsg-name $lockdown_nsg -g $shared_network_rg --priority 100 --direction Inbound --access Deny --source-address-prefixes Internet --destination-port-ranges '*' --protocol '*' --description "Block all inbound traffic"

# Create a jump box from which to test (as we will lock down external access)
vm_jump_obj=$(az vm create -g $shared_network_rg -n $vm_jump --image Win2016Datacenter --admin-username $vm_jump_username --vnet-name $network_name --subnet $services_subnet --public-ip-address "" --private-ip-address $vm_jump_privateip --authentication-type password --admin-password $vm_jump_adminpassword --size Standard_B2ms )

# Setting Azure DNS for the app doesn't appear to work so reverting to using a custom DNS server - 168.63.129.16
az network vnet update -g $shared_network_rg -n $network_name --dns-servers $vm_jump_privateip

# Create a Bastion
az network public-ip create -n BastionPIP -g $shared_network_rg --sku Standard
az network bastion create -n MyBastion --public-ip-address BastionPIP -g $shared_network_rg --vnet-name $network_name --location $location

#Need to disable subnet private endpoint policy
az network vnet subnet update -g $shared_network_rg --vnet-name $network_name -n $privateservices_subnet --disable-private-endpoint-network-policies true

# Centralise DNS zone creation
az network private-dns zone create -g $shared_network_rg -n "privatelink.queue.core.windows.net"
az network private-dns zone create -g $shared_network_rg -n "privatelink.file.core.windows.net"
az network private-dns zone create -g $shared_network_rg -n "privatelink.table.core.windows.net"
az network private-dns zone create -g $shared_network_rg -n "privatelink.blob.core.windows.net"
az network private-dns zone create -g $shared_network_rg -n "privatelink.documents.azure.com"
az network private-dns zone create -g $shared_network_rg -n "privatelink.vaultcore.azure.net"

az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.queue.core.windows.net" --name storagequeuevnet1link --virtual-network $network_name --registration-enabled false
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.blob.core.windows.net" --name blobvnet1link --virtual-network $network_name --registration-enabled false
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.documents.azure.com" --name sqlcosmosvnet1link --virtual-network $network_name --registration-enabled false
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.vaultcore.azure.net" --name vaultvnet1link --virtual-network $network_name --registration-enabled false
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.file.core.windows.net" --name storagefilevnet1link --virtual-network $network_name --registration-enabled false
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.table.core.windows.net" --name storagetablevnet1link --virtual-network $network_name --registration-enabled false

