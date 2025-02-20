# Configure Networking for Azure Kubernetes Service (AKS) (DRAFT)

## References

- [Azure Kubernetes Service Roadmap (Public)](https://aka.ms/aks/roadmap)

## Table of Contents

1. [Module 1](#module-1)
    1. [Clip 1 - Exposing Application Services](#clip-1---exposing-application-services)
    1. [Clip 2 - Demo: Configuring Kubernetes Services](#clip-2---demo-configuring-kubernetes-services)
    1. [Clip 3 - Distributing Web Application Traffic](#clip-3---distributing-web-application-traffic)
    1. [Clip 4 - Demo: Configuring the Application Routing Add-on](#clip-4---demo-configuring-the-application-routing-add-on)
    1. [Clip 5 - Demo: Configuring App Gateway for Containers](#clip-5---demo-configuring-app-gateway-for-containers)
1. [Module 2](#module-2)
    1. [Clip 1 - Securing Pod Traffic with Network Policies](#clip-1---securing-pod-traffic-with-network-policies)
    1. [Clip 2 - Demo: Enable and Configure Network Policies](#clip-2---demo-enable-and-configure-network-policies)

## Module 1

### Clip 1 - Exposing Application Services

- [Kubernetes Service documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes Services in AKS](https://learn.microsoft.com/azure/aks/concepts-network-services)

### Clip 2 - Demo: Configuring Kubernetes Services

To follow along in this demo using the Cloud Playground Sandbox, follow these steps:

1. Start an [Azure Sandbox](https://app.pluralsight.com/hands-on/playground/cloud-sandboxes).
1. In an InPrivate or Incognito window kog in to the Azure Sandbox using the provided credentials.
1. Click the **Deploy to Azure** button. Make sure the link opens in the Sandbox browser tab.

    [![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FWayneHoggett-ACG%2Faks-networking-draft%2Frefs%2Fheads%2Fmain%2F1.2%2Fmain.json)

1. Select the existing **Subscription** and **Resource Group**.
1. Provide the `Application Client ID` and `Secret` from the Sandbox details.
1. Deploy the template.
1. Follow-along with the demo.

### Clip 3 - Distributing Web Application Traffic

- [AKS - Best practices - Distribute ingress traffic](https://learn.microsoft.com/en-gb/azure/aks/operator-best-practices-network#distribute-ingress-traffic)
- [Kubernetes Ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/ )
- [Application Gateway for Containers](https://learn.microsoft.com/azure/application-gateway/for-containers/overview)
- [Gateway API](https://gateway-api.sigs.k8s.io/)

### Clip 4 - Demo: Configuring the Application Routing Add-on

To follow along in this demo using the Cloud Playground Sandbox, follow these steps:

1. Start an [Azure Sandbox](https://app.pluralsight.com/hands-on/playground/cloud-sandboxes).
1. In an InPrivate or Incognito window kog in to the Azure Sandbox using the provided credentials.
1. Click the **Deploy to Azure** button. Make sure the link opens in the Sandbox browser tab.

    [![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FWayneHoggett-ACG%2Faks-networking-draft%2Frefs%2Fheads%2Fmain%2F1.4%2Fmain.json)

1. Select the existing **Subscription** and **Resource Group**.
1. Provide the `Application Client ID` and `Secret` from the Sandbox details.
1. Deploy the template.
1. Follow-along with the demo.

### Clip 5 - Demo: Configuring App Gateway for Containers

1. To follow along with this demonstration you will need your own subscription.
1. Log in to the Azure Portal.
1. Open **Cloud Shell** using **Bash** and set the subscription you'd like to use:

    ```bash
    az account set --subscription "<Subscription ID>"
    ```

    >**Note**: Replace the value of `<Subscription ID>` with the ID of the subscription you'd like to use.

1. Create a resource group for the demonstration.

    > **Note**: You can change the name of the resource group and location as required. But you must use a region where App Gateway for Containers is available.

    ```bash
    RG=$(az group create --location australiaeast --resource-group rg-appgw-for-containers --query name --output tsv)
    ```

1. Click the **Deploy to Azure** button. Make sure the link opens in the same browser tab as the Azure Portal.

    [![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FWayneHoggett-ACG%2Faks-networking-draft%2Frefs%2Fheads%2Fmain%2F1.5%2Fmain.json)

1. Select your preferred **Subscription** and **Resource Group**.
1. Deploy the template.
1. Follow-along with the demo.

## Module 2

### Clip 1 - Securing Pod Traffic with Network Policies

- [Azure Kubernetes network policies](https://learn.microsoft.com/azure/virtual-network/kubernetes-network-policies)
- [AKS Best practices - Control traffic flow with network policies](https://learn.microsoft.com/azure/aks/operator-best-practices-network#control-traffic-flow-with-network-policies)
- [Secure traffic between pods by using network policies in AKS](https://learn.microsoft.com/azure/aks/use-network-policies)

### Clip 2 - Demo: Enable and Configure Network Policies

To follow along in this demo using the Cloud Playground Sandbox, follow these steps:

1. Start an [Azure Sandbox](https://app.pluralsight.com/hands-on/playground/cloud-sandboxes).
1. In an InPrivate or Incognito window kog in to the Azure Sandbox using the provided credentials.
1. Click the **Deploy to Azure** button. Make sure the link opens in the Sandbox browser tab.

    [![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FWayneHoggett-ACG%2Faks-networking-draft%2Frefs%2Fheads%2Fmain%2F2.2%2Fmain.json)

1. Select the existing **Subscription** and **Resource Group**.
1. Provide the `Application Client ID` and `Secret` from the Sandbox details.
1. Deploy the template.
1. Follow-along with the demo.