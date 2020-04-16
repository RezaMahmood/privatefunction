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