#Ensure network watcher is configured in the location
az network watcher configure -g $shared_network_rg --location $location --enabled

#Register the Insights provider
az provider register --namespace Microsoft.Insights

#Configure NSG flow logs.  We'll use the noaccess storage account used to simulate data exfiltration as the storage account cannot be network restricted as per https://docs.microsoft.com/en-gb/azure/network-watcher/network-watcher-nsg-flow-logging-cli
#Get the Storage account id
noaccess_storage_id=$(az resource show -g $shared_rg -n $noaccess_storage_name --resource-type "Microsoft.Storage/StorageAccounts" --query 'id' -o tsv)

#Create a Log Analytics workspace to enable traffic analytics
monitoring_workspace_object=$(az monitor log-analytics workspace create -g $shared_network_rg --workspace-name $monitoring_workspace -l $location)
monitoring_workspace_id=$(echo $monitoring_workspace_object | jq -rc '.id')
az network watcher flow-log create -g $shared_network_rg -n $nsg_flow_log_name --enabled true --format json --nsg $lockdown_nsg --storage-account $noaccess_storage_id --retention 30 --location $location --workspace $monitoring_workspace_id --traffic-analytics true