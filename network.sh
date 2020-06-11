
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
#Allow monitoring
az network nsg rule create --name allowmonitor1 --nsg-name $lockdown_nsg -g $shared_network_rg --priority 230 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefix ActionGroup --destination-port-ranges '*' --protocol '*' --description "Allow Azure Monitor"
az network nsg rule create --name allowmonitor2 --nsg-name $lockdown_nsg -g $shared_network_rg --priority 240 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefix ApplicationInsightsAvailability --destination-port-ranges '*' --protocol '*' --description "Allow Azure Monitor"
az network nsg rule create --name allowmonitor3 --nsg-name $lockdown_nsg -g $shared_network_rg --priority 250 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefix AzureMonitor --destination-port-ranges '*' --protocol '*' --description "Allow Azure Monitor"

az network nsg rule create --name blockinternet --nsg-name $lockdown_nsg -g $shared_network_rg --priority 300 --direction Outbound --access Deny --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet --destination-port-ranges '*' --protocol '*' --description "Block all internet traffic originating from vnet"

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

# Configure Firewall - https://docs.microsoft.com/en-us/azure/firewall/deploy-cli
az extension add -n azure-firewall
az network firewall create --name $firewall_name -g $shared_network_rg --location $location
az network public-ip create --name afw-pip --resource-group $shared_network_rg --location $location  --allocation-method static --sku standard
az network firewall ip-config create --firewall-name $firewall_name --name afw-config --public-ip-address afw-pip -g $shared_network_rg --vnet-name $network_name
az network firewall update --name $firewall_name -g $shared_network_rg

firewall_private_ip=$(az network firewall ip-config list -g $shared_network_rg -f $firewall_name --query "[?name=='afw-config'].privateIpAddress" --output tsv)

az network route-table create --name "$firewall_name-rt-table" -g $shared_network_rg --location $location --disable-bgp-route-propagation true
az network route-table route create -g $shared_network_rg --name function-route  --route-table-name "$firewall_name-rt-table" --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $firewall_private_ip
az network vnet subnet update -n $function_subnet -g $shared_network_rg --vnet-name $network_name --address-prefixes 10.1.2.0/27 --route-table "$firewall_name-rt-table"

#Allow Function app to access storage through the Firewall
az network firewall application-rule create --collection-name App-Function --firewall-name $firewall_name --name allowAppStorage --protocols Http=80 Https=443 -g $shared_network_rg --action Allow --target-fqdns "$func_storage_name.blob.core.windows.net" "$func_storage_name.files.core.windows.net" "$func_storage_name.table.core.windows.net" "$func_storage_name.queue.core.windows.net" "$funcjob_storage_name.blob.core.windows.net" "$funcjob_storage_name.files.core.windows.net" "$funcjob_storage_name.table.core.windows.net" "$funcjob_storage_name.queue.core.windows.net" --priority 200 --source-addresses "10.1.2.0/27" "10.1.0.0/27"
az network firewall application-rule create --collection-name App-Function --firewall-name $firewall_name --name allowAppInsights --protocols Http=80 Https=443 -g $shared_network_rg --action Allow --target-fqdns "*.services.visualstudio.com" "*.applicationinsights.microsoft.com" "*.applicationinsights.azure.com"  --source-addresses "10.1.2.0/27" "10.1.0.0/27"