#Create Resource Groups for the application
az group create -l $location -n $shared_rg
az group create -l $location -n $shared_network_rg
az group create -l $location -n $app_rg