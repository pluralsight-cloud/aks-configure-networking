
# Create New Subnet in AKS Managed Virtual network
echo "Retrieving AKS managed virtual network information"
MC_RG=$(az aks show --name $AKS --resource-group $RG --query "nodeResourceGroup" -o tsv)
CLUSTER_SUBNET_ID=$(az vmss list --resource-group $MC_RG --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv)
read -d '' VNET_NAME VNET_RG VNET_ID <<< $(az network vnet show --ids $CLUSTER_SUBNET_ID --query '[name, resourceGroup, id]' -o tsv)

echo "Creating subnet for Application Load Balancer"
SUBNET_ADDRESS_PREFIX='10.225.0.0/24' #network address and prefix for an address space under the vnet that has at least 250 available addresses (/24 or larger subnet)
ALB_SUBNET_NAME='subnet-alb' # subnet name can be any non-reserved subnet name (i.e. GatewaySubnet, AzureFirewallSubnet, AzureBastionSubnet would all be invalid)
az network vnet subnet create --resource-group $VNET_RG --vnet-name $VNET_NAME --name $ALB_SUBNET_NAME --address-prefixes $SUBNET_ADDRESS_PREFIX --delegations 'Microsoft.ServiceNetworking/trafficControllers'
export ALB_SUBNET_ID=$(az network vnet subnet show --name $ALB_SUBNET_NAME --resource-group $VNET_RG --vnet-name $VNET_NAME --query '[id]' --output tsv)

# Delegate permissions to managed identity
echo "Retrieving principalId for azure-alb-identity"
IDENTITY_RESOURCE_NAME='azure-alb-identity'
MC_RG=$(az aks show --name $AKS --resource-group $RG --query "nodeResourceGroup" -otsv | tr -d '\r')
mcResourceGroupId=$(az group show --name $MC_RG --query id -otsv)
principalId=$(az identity show -g $RG -n $IDENTITY_RESOURCE_NAME --query principalId -otsv)

# Delegate AppGw for Containers Configuration Manager role to AKS Managed Cluster RG
echo "Delegating AppGw for Containers Configuration Manager role to AKS Managed Cluster RG"
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $mcResourceGroupId --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"

# Delegate Network Contributor permission for join to association subnet
echo "Delegating Network Contributor permission for join to association subnet"
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $ALB_SUBNET_ID --role "4d97b98b-1d4f-4787-a291-c67834d212e7"

# Define the Kubernetes namespace for the ApplicationLoadBalancer resource
echo "Creating namespace alb-infrastructure"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: alb-infrastructure
EOF

# Create the Application Gateway for Containers resource and association
echo "Creating ApplicationLoadBalancer resource"
kubectl apply -f - <<EOF
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb
  namespace: alb-infrastructure
spec:
  associations:
  - $ALB_SUBNET_ID
EOF