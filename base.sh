
version=$RANDOM

location="southeastasia"
shared_rg="PrivateFunctionSharedRG"
shared_network_rg="PrivateFunctionNetworkRG"
app_rg="PrivateFunctionAppRG"

# Networking variables
network_name="vnet1"
services_subnet="services"
privateservices_subnet="privateservices"
function_subnet="functionapp"
lockdown_nsg="Lockdown"
nsg_flow_log_name="lockdown_flowlog"
monitoring_workspace="contosofuncmon"$version
firewall_name="afw1"

# Shared resources
cosmosdb_account_name="contosocosmos"$version
cosmosdb_database_name="contosodb"
cosmosdb_container_name="contosocontainer"

storage_name="contososharedstor"$version
storage_access_tier="Hot"
storage_sku="Standard_LRS"
storage_kind="StorageV2"
storage_queue="queue"
storage_container="sharedcontainer"
storage_container_file="sourcerecords.txt"
eventhub_name="contososharedhub"$version
eventhub_namespace="contosohub"$version

noaccess_storage_name="acmenoaccess"$version
noaccess_storage_access_tier="Hot"
noaccess_storage_sku="Standard_LRS"
noaccess_storage_kind="StorageV2"
noaccess_storage_container="accessdenied"
noaccess_storage_file="noaccess.txt"

# Functions App
functionapp_name="contosofuncapp"$version
functionapp_plan="contosofuncplan"

func_storage_name="contosofuncastor"$version
funcjob_storage_name="contosofuncjstor"$version
func_storage_access_tier="Hot"
func_storage_sku="Standard_LRS"
func_storage_kind="StorageV2"

vm_jump="contosovm"$version
vm_jump_username="contosouser"
vm_jump_adminpassword="contososupersecretpassword1@"
vm_jump_privateip="10.1.0.4"

# Keyvault
keyvault_name="contosokv"$version
keyvault_secret_name="contososecret"
keyvault_secret_value="Super Secret Keyvault protected text"

