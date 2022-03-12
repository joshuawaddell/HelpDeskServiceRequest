# HelpDeskServiceRequest

TODO: Insert text here...


## Prerequisites

To deploy the Help Desk Service Request application to Azure, it is necessary to complete some pre-requisites, both in Azure and in GitHub.

Azure

- Resource Groups
- Azure Key Vault
- Azure User Assigned Managed Identity
- Azure App Registration (Service Principal)

GitHub

- Repository Secrets

### Azure Setup

#### Resource Groups

The application deployment uses two Azure Resource Groups (core and app). The 'core' Resource Group is created prior to the deployment, and the 'app' Resource Group is created during the deployment. Prior to creating the 'core' Resource Group it is necessary to define a series of variables that will be used throughout the deployment. These variables are used to build resource names and are used in any AZ CLI script, PowerShell script, ARM Template, and YAML workflow to deploy the infrastructure and application. The following variables must be defined:

- `workload` - defines the name of the workload to be deployed (e.g. `helpdesk`, `hdsr`)
- `env` - defines the name of the environment to be deployed to (e.g. `prod`, `dev`, or `test`)
- `azureRegion` - defines the name of the Azure Region to be deployed to (e.g. `eastus`, `eastus2`)

The 'core' Resource Group can be created in the Azure Portal, or using Azure CLI or Azure PowerShell. This guide focuses on using AZ CLI. 

To create the 'core' Resource Group, open a terminal and run the following command using the appropriate variables:

```powershell
$azureRegion = 'NAME OF THE AZURE REGION'
$resourceGroupName = "rg-${workload}-${env}-${azureRegion}-core"

az group create -n $resourceGroupName -l $azureRegion
```

For example:

```powershell
$azureRegion = 'eastus'
$resourceGroupName = "rg-hdsr-prod-eastus-core"

az group create -n $resourceGroupName -l $azureRegion
```

#### Key Vault

The application deployment uses an Azure Key Vault to store two secrets. The first secret is for the admin password of any resources deployed, and the second secret is for the base64 encoded PFX certificate used by the Azure Application Gateway.

##### Create the Azure Key Vault

To create the Azure Key Vault, open a terminal and run the following command using the appropriate variables:

```powershell
$azureRegion = 'NAME OF THE AZURE REGION'
$resourceGroupName = "rg-${workload}-${env}-${azureRegion}-core"
$keyValutName = "kv-${workload}-${env}-${azureRegion}"

az keyvault create -n $keyVaultName -g $resourceGroupName --enable-soft-delete true --retention-days 7 --enable-purge-protection true --enabled-for-deployment true --enabled-for-disk-encryption true --enabled-for-template-deployment true
```

For example:

```powershell
$azureRegion = 'eastus'
$resourceGroupName = "rg-hdsr-prod-eastus-core"
$keyValutName = "kv-hdsr-prod-eastus"

az keyvault create -n $keyVaultName -g $resourceGroupName --enable-soft-delete true --retention-days 7 --enable-purge-protection true --enabled-for-deployment true --enabled-for-disk-encryption true --enabled-for-template-deployment true
```

##### Create the Azure Key Vault Secret for the Admin Password

To create the Azure Key Vault Secret for the admin password, open a terminal and run the following command using the appropriate variables:

```powershell
$keyValutName = "kv-${workload}-${env}-${azureRegion}"
$secretName = 'NAME OF SECRET'
$secretValue = 'VALUE OF SECRET'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

For example:

```powershell
$keyValutName = "kv-hdsr-prod-eastus"
$adminPassword = 'adminPassword'
$secretValue = 'abc123!'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

##### Create the Azure Key Vault Secret for the base64 Encoded PFX Certificate

Before creating the Azure Key Vault Secret for the base64 encoded PFX certificate, it is necessary to convert an existing PFX certificate to base 64 using PowerShell.

To convert an existing PFX certificate to base 64, open a PowerShell terminal and run the following command using the appropriate variables:

```powershell
$fileContentBytes = get-content 'PATH TO YOUR PFX FILE' -Encoding Byte
[System.Convert]::ToBase64String($fileContentBytes) | Out-File ‘pfx-encoded-bytes.txt’
```

To create the Azure Key Vault Secret for the base64 encoded PFX certificate, open a terminal and run the following command using the appropriate variables:

```azcli
$keyValutName = "kv-${workload}-${env}-${azureRegion}"
$secretName = 'Name of Secret
$secretValue = 'Value of Secret'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

For example:

```azcli
$keyValutName = "kv-hdsr-prod-eastus"
$adminPassword = 'certificate'
$secretValue = 'abc123!'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

User Assigned Managed Identity

#### Service Principal

To deploy the Azure infrastructure and the application code, a Service Principal, also known as an App Registration, needs to be created in  Azure Active Directory. The [`az ad sp create-for-rbac`](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) command is used to create the Service Principal with an appropriate role at the appropriate scope for deployment.

```azcli
az ad sp create-for-rbac -n 'name of service principal' --role Contributor --scopes 'subscription id' --sdk-auth
```

The output of the command will appear as follows:

```json
{
  "clientId": "The Client ID of the Service Principal",
  "clientSecret": "The Client Secret of the Service Principal",
  "subscriptionId": "The Azure Subscription ID",
  "tenantId": "The Azure Active Directory Tenant ID",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### GitHub Setup

TODO: Insert text here...

## Todo

- Documentation
- GitHub Actions workflow for application deployment
- Provide method to inject parameter values for workload, environment, and Azure region
- Visio Diagram
