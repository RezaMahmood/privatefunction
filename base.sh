
subscriptionId="4fe0a42b-c304-4bd3-8d1d-42efcdf1a0a1"
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

cosmosdb_account_name="rezacosmosacc"
sharedstorage_name="rezafuncstor"
eventhub_name="rezasharedhub"
eventhub_namespace="rezahub"

vm_dns="rezadns"
vm_dns_username="rezauser"
vm_dns_adminpassword="rezasupersecretpassword1@"
vm_dns_privateip="10.1.0.4"


az account set -s $subscriptionId

#Create Resource Groups for the application
az group create -l $location -n $shared_rg
az group create -l $location -n $shared_network_rg
az group create -l $location -n $app_rg