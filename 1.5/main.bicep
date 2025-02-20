
var location  = resourceGroup().location
var osDiskSizeGB  = 128
var agentCount = 1
var agentVMSize = 'Standard_D2s_v3'
var osTypeLinux = 'Linux'
var uniqueSuffix = uniqueString(resourceGroup().id)

var roleDefinitionId = {
  AcrPull: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
  Contributor: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  }
}

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
    networkProfile: {
      networkPlugin: 'azure'
    }
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

resource AssignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, containerRegistry.name, aksCluster.name, 'ACRPull')
  scope: containerRegistry
  properties: {
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionId['AcrPull'].id
  }
}

resource deploymentScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'DeploymentScriptIdentity'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(deploymentScriptIdentity.id, resourceGroup().id, 'Contributor')
  scope: resourceGroup()
  properties: {
    description: 'Managed identity role assignment'
    principalId: deploymentScriptIdentity.properties.principalId
    roleDefinitionId: roleDefinitionId['Contributor'].id
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-deploymentscript'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${deploymentScriptIdentity.id}': {}
    }
  }
  dependsOn: [
    containerRegistry
    aksCluster
  ]
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: '1'
    azCliVersion:  '2.9.1'
    scriptContent: '''
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
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
    kubectl create deployment web --image=$ACR_LOGIN_SERVER/web:v1 --namespace globalmanticsbooks --replicas=1 --port=80
    kubectl create deployment api --image=$ACR_LOGIN_SERVER/api:v1 --namespace globalmanticsbooks --replicas=1 --port=5000
    kubectl expose deployment/api --port=80 --target-port=5000
    kubectl set env deployment/web BOOKS_API_URL=http://api
    kubectl expose deployment/web --port=80 --target-port=80
    # Create an Ingress for the web app
    kubectl create ingress web --rule="/=web:80" --class=webapprouting.kubernetes.azure.com
    # Patch in the pathType to Prefix
    kubectl patch ingress web --type='json' -p='[{"op": "add", "path": "/spec/rules/0/http/paths/0/pathType", "value": "Prefix"}]'
    '''
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT1H'
  }
}
