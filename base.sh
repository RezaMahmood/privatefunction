
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
cosmosdb_account_name="rezacosmosacc2"
cosmosdb_database_name="rezadb"
cosmosdb_container_name="rezacontainer"

storage_name="rezasharedstor5"
storage_access_tier="Hot"
storage_sku="Standard_LRS"
storage_kind="StorageV2"
storage_queue="queue"
storage_container="sharedcontainer"
storage_container_file="sourcerecords.txt"
eventhub_name="rezasharedhub"
eventhub_namespace="rezahub"

noaccess_storage_name="rezanoaccess2"
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

vm_dns="rezajump"
vm_dns_username="rezauser"
vm_dns_adminpassword="rezasupersecretpassword1@"
vm_dns_privateip="10.1.0.4"

# Keyvault
keyvault_name="rezakv3"
keyvault_secret_name="rezasecret"
keyvault_secret_value="Super Secret Keyvault protected text"

