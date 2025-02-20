
@description('The tenant ID for the Service Principal (Application), use the default value for the Sandbox')
param tenantId string = '84f1e4ea-8554-43e1-8709-f0b8589ea118'
@description('The Client ID for the Service Principal (Application). Retrieve this value from the details of your Sandbox instance.')
param applicationClientId string
@secure()
@description('The Client Secret for the Service Principal (Application). Retrieve this value from the details of your Sandbox instance.')
param applicationClientSecret string

var location  = resourceGroup().location
var osDiskSizeGB  = 128
var agentCount = 1
var agentVMSize = 'Standard_D2s_v3'
var osTypeLinux = 'Linux'
var uniqueSuffix = uniqueString(resourceGroup().id)

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: 'cr${uniqueSuffix}'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    anonymousPullEnabled: true
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-06-02-preview' = {
  location: location
  name: 'aks-${uniqueSuffix}'
  tags: {
    displayname: 'AKS Cluster'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: true
    dnsPrefix: 'aks-${uniqueSuffix}'
    agentPoolProfiles: [
      {
        name: 'syspool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: osTypeLinux
        type: 'VirtualMachineScaleSets'
        mode: 'System'
      }
    ]
    ingressProfile: {
      webAppRouting: {
        enabled: true
      }
    }
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-deploymentscript'
  location: location
  dependsOn: [
    containerRegistry
    aksCluster
  ]
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: '1'
    azCliVersion:  '2.9.1'
    environmentVariables: [
      {
        name: 'APP_ID'
        value: applicationClientId
      }
      {
        name: 'CLIENT_SECRET'
        value: applicationClientSecret
      }
      {
        name: 'TENANT_ID'
        value: tenantId
      }
    ]
    scriptContent: '''
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    # Install Helm
	  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	  chmod 700 get_helm.sh
	  ./get_helm.sh
    az login --service-principal --username $APP_ID --password $CLIENT_SECRET --tenant $TENANT_ID
    RG=$(az group list --query [].name --output tsv)
    AKS=$(az aks list --resource-group $RG --query [].name --output tsv)
    ACR=$(az acr list --resource-group $RG --query [].name --output tsv)
    ACR_LOGIN_SERVER=$(az acr show --name $ACR --query loginServer --output tsv)
    # Build the Container Images
    git clone https://github.com/WayneHoggett-ACG/GlobalmanticsBooks
    cd GlobalmanticsBooks
    cd api
    az acr build --registry $ACR --image api:v1 .
    cd ../web
    az acr build --registry $ACR --image web:v1 .
    # Connect to the AKS cluster
    az aks get-credentials --resource-group $RG --name $AKS
    # Create the Namespace and Application
    kubectl create namespace globalmanticsbooks --save-config
    kubectl config set-context --current --namespace=globalmanticsbooks
    cd ../helm
    helm install globalmanticsbooks ./globalmanticsbooks --namespace globalmanticsbooks --create-namespace --set ContainerRegistryFQDN=$ACR_LOGIN_SERVER
    '''
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT1H'
  }
}
