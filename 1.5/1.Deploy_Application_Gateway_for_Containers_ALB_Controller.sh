# Register required resource providers on Azure.
echo "Registering required resource providers on Azure"
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking

# Install Azure CLI extensions.
echo "Installing Azure CLI extension: alb"
az extension add --name alb

# Ensure workload identity is enabled on the existing cluster
echo "Enabling Workload Identity on AKS cluster"
az aks update -g $RG -n $AKS --enable-oidc-issuer --enable-workload-identity

# Create a user managed identity for ALB controller and federate the identity as Workload Identity to use in the AKS cluster
echo "Retrieving MC resource group details"
IDENTITY_RESOURCE_NAME='azure-alb-identity'
MC_RG=$(az aks show --resource-group $RG --name $AKS --query "nodeResourceGroup" -o tsv)
MC_RG_ID=$(az group show --name $MC_RG --query id -o tsv)

echo "Creating identity $IDENTITY_RESOURCE_NAME in resource group $RG"
az identity create --resource-group $RG --name $IDENTITY_RESOURCE_NAME
principalId="$(az identity show -g $RG -n $IDENTITY_RESOURCE_NAME --query principalId -otsv)"

echo "Waiting 120 seconds to allow for replication of the identity..."
sleep 120

echo "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $MC_RG_ID --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

echo "Set up federation with AKS OIDC issuer"
AKS_OIDC_ISSUER="$(az aks show -n "$AKS" -g "$RG" --query "oidcIssuerProfile.issuerUrl" -o tsv)"
az identity federated-credential create --name "azure-alb-identity" --identity-name "$IDENTITY_RESOURCE_NAME" --resource-group $RG --issuer "$AKS_OIDC_ISSUER" --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# Install the ALB Controller
echo "Installing ALB Controller"
HELM_NAMESPACE='helm'
CONTROLLER_NAMESPACE='azure-alb-system'
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller --namespace $HELM_NAMESPACE --create-namespace --version 1.3.7 --set albController.namespace=$CONTROLLER_NAMESPACE --set albController.podIdentity.clientID=$(az identity show -g $RG -n azure-alb-identity --query clientId -o tsv)