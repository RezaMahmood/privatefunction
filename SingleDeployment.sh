# All in one script
location="southeastasia"
shared_rg="PrivateFunctionSharedRG"
shared_network_rg="PrivateFunctionNetworkRG"
app_rg="PrivateFunctionAppRG"

# Networking variables
network_name="vnet1"
services_subnet="services"
privateservices_subnet="privateservices"
function_subnet="functionapp"

# Shared resources
cosmosdb_account_name="rezacosmosacc"
cosmosdb_database_name="rezadb"
cosmosdb_container_name="rezacontainer"

storage_name="rezasharedstor2"
storage_access_tier="Hot"
storage_sku="Standard_LRS"
storage_kind="StorageV2"
storage_queue="queue"
storage_container="sharedcontainer"
storage_container_file="sourcerecords.txt"

eventhub_name="rezasharedhub"
eventhub_namespace="rezahub"

noaccess_storage_name="rezanoaccess"
noaccess_storage_access_tier="Hot"
noaccess_storage_sku="Standard_LRS"
noaccess_storage_kind="StorageV2"
noaccess_storage_container="accessdenied"
noaccess_storage_file="noaccess.txt"

# Functions App
functionapp_name="rezafuncapp"
functionapp_plan="rezafuncplan"

func_storage_name="rezafuncappstor"
func_storage_access_tier="Hot"
func_storage_sku="Standard_LRS"
func_storage_kind="StorageV2"

vm_dns="rezadns"
vm_dns_username="rezauser"
vm_dns_adminpassword="rezasupersecretpassword1@"
vm_dns_privateip="10.1.0.4"

# Set up ADO specific environment variables
echo "##vso[task.setvariable variable=location]$location"
echo "##vso[task.setvariable variable=shared_rg]$shared_rg"
echo "##vso[task.setvariable variable=shared_network_rg]$shared_network_rg"
echo "##vso[task.setvariable variable=app_rg]$app_rg"
echo "##vso[task.setvariable variable=location]$location"

# Networking variables
echo "##vso[task.setvariable variable=network_name]$network_name"
echo "##vso[task.setvariable variable=services_subnet]$services_subnet"
echo "##vso[task.setvariable variable=privateservices_subnet]$privateservices_subnet"
echo "##vso[task.setvariable variable=function_subnet]$function_subnet"

# Shared resources
echo "##vso[task.setvariable variable=cosmosdb_account_name]$cosmosdb_account_name"
echo "##vso[task.setvariable variable=cosmosdb_database_name]$cosmosdb_database_name"
echo "##vso[task.setvariable variable=cosmosdb_container_name]$cosmosdb_container_name"

echo "##vso[task.setvariable variable=storage_name]$storage_name"
echo "##vso[task.setvariable variable=storage_access_tier]$storage_access_tier"
echo "##vso[task.setvariable variable=storage_sku]$storage_sku"
echo "##vso[task.setvariable variable=storage_kind]$storage_kind"
echo "##vso[task.setvariable variable=storage_queue]$storage_queue"
echo "##vso[task.setvariable variable=storage_container]$storage_container"
echo "##vso[task.setvariable variable=storage_container_file]$storage_container_file"

echo "##vso[task.setvariable variable=eventhub_name]$eventhub_name"
echo "##vso[task.setvariable variable=eventhub_namespace]$eventhub_namespace"

echo "##vso[task.setvariable variable=noaccess_storage_name]$noaccess_storage_name"
echo "##vso[task.setvariable variable=noaccess_storage_access_tier]$noaccess_storage_access_tier"
echo "##vso[task.setvariable variable=noaccess_storage_sku]$noaccess_storage_sku"
echo "##vso[task.setvariable variable=noaccess_storage_kind]$noaccess_storage_kind"
echo "##vso[task.setvariable variable=noaccess_storage_container]$noaccess_storage_container"
echo "##vso[task.setvariable variable=noaccess_storage_file]$noaccess_storage_file"

# Functions App
echo "##vso[task.setvariable variable=func_storage_name]$func_storage_name"
echo "##vso[task.setvariable variable=func_storage_access_tier]$func_storage_access_tier"
echo "##vso[task.setvariable variable=func_storage_sku]$func_storage_sku"
echo "##vso[task.setvariable variable=func_storage_kind]$func_storage_kind"

echo "##vso[task.setvariable variable=vm_dns]$vm_dns"
echo "##vso[task.setvariable variable=vm_dns_username]$vm_dns_username"
echo "##vso[task.setvariable variable=vm_dns_adminpassword]$vm_dns_adminpassword"
echo "##vso[task.setvariable variable=vm_dns_privateip]$vm_dns_privateip"

#Create Resource Groups for the application
az group create -l $location -n $shared_rg
az group create -l $location -n $shared_network_rg
az group create -l $location -n $app_rg


az network vnet create -g $shared_network_rg -n $network_name --address-prefix 10.1.0.0/16 --subnet-name $services_subnet --subnet-prefix 10.1.0.0/27

az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n $privateservices_subnet --address-prefixes 10.1.1.0/27

az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n $function_subnet --address-prefixes 10.1.2.0/27

az network vnet subnet create -g $shared_network_rg --vnet-name $network_name -n "AzureBastionSubnet" --address-prefixes 10.1.3.0/27

#Create rules to estrict all outbound access from the vnet
az network nsg create --name Lockdown -g $shared_network_rg
az network nsg rule create --name blockoutrule --nsg-name Lockdown -g $shared_network_rg --priority 300 --direction Outbound --access Deny --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet --destination-port-ranges '*' --protocol '*' --description "Block all outbound traffic origination from vnet"
az network nsg rule create --name allowdns --nsg-name Lockdown -g $shared_network_rg --priority 200 --direction Outbound --access Allow --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet --destination-port-ranges 53 --protocol '*' --description "Allow DNS queries"

# Create rules to restrict all inbound access from the vnet
az network nsg rule create --name blockinrule --nsg-name Lockdown -g $shared_network_rg --priority 100 --direction Inbound --access Deny --source-address-prefixes Internet --destination-port-ranges '*' --protocol '*' --description "Block all inbound traffic"

# Create a DNS server
# Note this could be done with bind9 on linux and only using forwarder DNS resolution with 168.63.129.16 - ##TODO
vm_dns_obj=$(az vm create -g $shared_network_rg -n $vm_dns --image Win2016Datacenter --admin-username $vm_dns_username --vnet-name $network_name --subnet $services_subnet --public-ip-address "" --private-ip-address $vm_dns_privateip --authentication-type password --admin-password $vm_dns_adminpassword --size Standard_B2ms )

# Create a Bastion
az network public-ip create -n BastionPIP -g $shared_network_rg --sku Standard
az network bastion create -n MyBastion --public-ip-address BastionPIP -g $shared_network_rg --vnet-name $network_name --location $location

# Reference new VM as the DNS server for the vnet
az network vnet update -g $shared_network_rg -n $network_name --dns-servers $vm_dns_privateip

# Create the basic shared resources needed for the application
# CosmosDB
# Storage Account (for Storage queues)
# Service Bus
# Event Hub
# Key Vault


#Storage Account
storage_object=$(az storage account create --name $storage_name --resource-group $shared_rg --location $location --access-tier $storage_access_tier --sku $storage_sku --kind $storage_kind)
storage_id=$(echo $storage_object | jq -rc '.id')
storage_key=$(az storage account keys list --account-name $storage_name --query '[0]'.value -o tsv)

# Create a queue to test initial simple case of reading off queue to store into CosmosDB
az storage queue create --name $storage_queue --account-name $storage_name --account-key $storage_key --auth-mode key

# Create a blob container to simulate a file landing
az storage container create --name $storage_container --account-name $storage_name --account-key $storage_key --auth-mode key

#Note to self: precedence appears to be important
#Need to disable subnet private endpoint policy
az network vnet subnet update -g $shared_network_rg --vnet-name $network_name -n $privateservices_subnet --disable-private-endpoint-network-policies true
# Create private endpoint for the queue endpoint of the shared storage account
az network private-endpoint create --name ${storage_name}-pe --connection-name ${storage_name}-queue-conn -g $shared_network_rg --vnet-name $network_name --subnet $privateservices_subnet --private-connection-resource-id $storage_id --group-ids queue
# Create private DNS zone for the private queue endpoint
az network private-dns zone create -g $shared_network_rg -n "privatelink.queue.core.windows.net"
az network private-dns link vnet create -g $shared_network_rg --zone-name "privatelink.queue.core.windows.net" --name sharedqueuednslink --virtual-network $network_name --registration-enabled false

#Query for the network interface ID created as part of private endpoint
storage_networkInterfaceId=$(az network private-endpoint show --name ${storage_name}-pe --resource-group $shared_network_rg --query 'networkInterfaces[0].id' -o tsv)
storage_nic_object=$(az resource show --ids $storage_networkInterfaceId --api-version 2019-04-01 -o json)
# Get the content for privateIPAddress and FQDN matching the SQL server name - this needs to have jq installed - https://stedolan.github.io/jq/
storage_nic_ip=$(echo $storage_nic_object | jq -rc '.properties.ipConfigurations[0].properties.privateIPAddress')

#Create DNS records 
az network private-dns record-set a create --name $storage_name --zone-name "privatelink.queue.core.windows.net" --resource-group $shared_network_rg  
az network private-dns record-set a add-record --record-set-name $storage_name --zone-name "privatelink.queue.core.windows.net" --resource-group $shared_network_rg -a $storage_nic_ip

# Create the storage account that the Function should not have access to
az storage account create --name $noaccess_storage_name --resource-group $shared_rg --location $location --access-tier $noaccess_storage_access_tier --sku $noaccess_storage_sku --kind $noaccess_storage_kind
noaccess_storage_key=$(az storage account keys list --account-name $noaccess_storage_name --query '[0]'.value -o tsv)
az storage container create --name $noaccess_storage_container --account-name $noaccess_storage_name --account-key $noaccess_storage_key --auth-mode key
# Upload a file that should not be accessible from the Function if the Function has the correct access key to it
noaccess_storage_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $noaccess_storage_name --query connectionString -o tsv)
az storage blob upload --account-name $noaccess_storage_name -f $noaccess_storage_file -c $noaccess_storage_container -n $noaccess_storage_file --connection-string $noaccess_storage_connectionstring

#CosmosDB
az cosmosdb create -n $cosmosdb_account_name -g $shared_rg --locations regionName=$location
az cosmosdb sql database create -a $cosmosdb_account_name -g $shared_rg -n $cosmosdb_database_name
az cosmosdb sql container create -a $cosmosdb_account_name -g $shared_rg -n $cosmosdb_container_name -p '/id' --throughput 400 -d $cosmosdb_database_name


# Create an Event Hub as a sink for blob file records
az eventhubs namespace create --name $eventhub_namespace -g $shared_rg --sku Basic --location $location
az eventhubs eventhub create --name $eventhub_name -g $shared_rg --namespace-name $eventhub_namespace --message-retention 1
# Create a Send policy
az eventhubs eventhub authorization-rule create --eventhub-name $eventhub_name --name Send -g $shared_rg --namespace-name $eventhub_namespace --rights Send

#Separate Storage account for Functions backing store
az storage account create --name $func_storage_name --resource-group $app_rg --location $location --access-tier $func_storage_access_tier --sku $func_storage_sku --kind $func_storage_kind

az functionapp plan create --name $functionapp_plan -g $app_rg --location $location --sku EP1

az functionapp create --name $functionapp_name --resource-group $app_rg --storage-account $func_storage_name --runtime-version 3 --functions-version 3 --os-type Linux --runtime dotnet --plan $functionapp_plan

#Configure vnet integration
az functionapp vnet-integration add -g $app_rg --name $functionapp_name --vnet $network_name --subnet $function_subnet

#Configure application settings
cosmos_connectionstring=$(az cosmosdb keys list --name $cosmosdb_account_name -g $shared_rg --type connection-strings --query 'connectionStrings[0].connectionString' -o tsv)
sharedstor_connectionstring=$(az storage account show-connection-string -g $shared_rg -n $storage_name --query connectionString -o tsv)
eventhub_connectionstring=$(az eventhubs eventhub authorization-rule keys list -g $shared_rg --namespace-name $eventhub_namespace --eventhub-name $eventhub_name -n Send --query primaryConnectionString -o tsv)

az functionapp config appsettings set -n $functionapp_name -g $app_rg --settings "CosmosDBConnection"=$cosmos_connectionstring "SharedStor"=$sharedstor_connectionstring "EventHubConnection"=$eventhub_connectionstring "EventHubName"="rezasharedhub" WEBSITE_VNET_ROUTE_ALL=1 "GetUrls=https://www.microsoft.com/;https://www.google.com/;https://www.dropbox.com/" "Blob.Path=$noaccess_storage_container/$noaccess_storage_file" WEBSITE_DNS_SERVER=$vm_dns_privateip

#Enable virtual network trigger support - https://docs.microsoft.com/en-gb/azure/azure-functions/functions-networking-options#virtual-network-triggers-non-http
az resource update -g $app_rg -n $functionapp_name/config/web --set properties.functionsRuntimeScaleMonitoringEnabled=1 --resource-type Microsoft.Web/sites