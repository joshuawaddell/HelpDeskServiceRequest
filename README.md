# HelpDeskServiceRequest

TODO: Insert text here...


## Prerequisites

To deploy the Help Desk Service Request application to Azure, it is necessary to complete some pre-requisites, both in Azure and in GitHub.

Core

- Domain Name
- Wildcard PFX Certificate

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
$workload = 'Name of the workload'
$env = 'Name of the environment'
$azureRegion = 'Name of the Azure Region'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'

az group create -n $resourceGroupName -l $azureRegion
```

For example:

```powershell
$workload = 'hdsr'
$env = 'prod'
$azureRegion = 'eastus'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'

az group create -n $resourceGroupName -l $azureRegion
```

#### Azure Key Vault

The application deployment uses an Azure Key Vault to store two secrets. The first secret is for the admin password of any resources deployed, and the second secret is for the base64 encoded PFX certificate used by the Azure Application Gateway.

##### Create the Azure Key Vault

To create the Azure Key Vault, open a terminal and run the following command using the appropriate variables:

```powershell
$workload = 'Name of the workload'
$env = 'Name of the environment'
$azureRegion = 'Name of the Azure Region'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'
$keyValutName = 'kv-$workload-$env-$azureRegion'

az keyvault create -n $keyVaultName -g $resourceGroupName --enable-soft-delete true --retention-days 7 --enable-purge-protection true --enabled-for-deployment true --enabled-for-disk-encryption true --enabled-for-template-deployment true
```

For example:

```powershell
$workload = 'hdsr'
$env = 'prod'
$azureRegion = 'eastus'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'
$keyValutName = 'kv-$workload-$env-$azureRegion'

az keyvault create -n $keyVaultName -g $resourceGroupName --enable-soft-delete true --retention-days 7 --enable-purge-protection true --enabled-for-deployment true --enabled-for-disk-encryption true --enabled-for-template-deployment true
```

##### Create the Azure Key Vault Secret for the Admin Password

To create the Azure Key Vault Secret for the admin password, open a terminal and run the following command using the appropriate variables:

```powershell
$workload = 'Name of the workload'
$env = 'Name of the environment'
$azureRegion = 'Name of the Azure Region'
$keyValutName = 'kv-$workload-$env-$azureRegion'
$secretName = 'Name of secret'
$secretValue = 'Value of secret'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

For example:

```powershell
$workload = 'hdsr'
$env = 'prod'
$azureRegion = 'eastus'
$keyValutName = 'kv-$workload-$env-$azureRegion'
$adminPassword = 'adminPassword'
$secretValue = 'abc123!'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

##### Create the Azure Key Vault Secret for the base64 Encoded PFX Certificate

Before creating the Azure Key Vault Secret for the base64 encoded PFX certificate, it is necessary to convert an existing PFX certificate to base 64 using PowerShell.

To convert an existing PFX certificate to base 64, open a PowerShell terminal and run the following command using the appropriate variables:

```powershell
$pfxPath = 'Path to your PFX file'
$txtPath = 'Path to your TXT file'
$fileContentBytes = get-content '$certificatePath' -Encoding Byte
[System.Convert]::ToBase64String($fileContentBytes) | Out-File $txtPath
```

For example:

```powershell
$pfxPath = 'C:\certificates\wildcard.pfx'
$txtPath = 'wildcard.txt'
$fileContentBytes = get-content '$certificatePath' -Encoding Byte
[System.Convert]::ToBase64String($fileContentBytes) | Out-File $txtPath
```

After converting the PFX certificate to base64 encoded format, open the text file and copy the contents. This is used as the secret value in the next step.

To create the Azure Key Vault Secret for the base64 encoded PFX certificate, open a terminal and run the following command using the appropriate variables:

```powershell
$workload = 'Name of the workload'
$env = 'Name of the environment'
$azureRegion = 'Name of the Azure Region'
$keyValutName = 'kv-$workload-$env-$azureRegion'
$secretName = 'Name of secret'
$secretValue = 'Value of secret'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

For example:

```powershell
$workload = 'hdsr'
$env = 'prod'
$azureRegion = 'eastus'
$keyValutName = 'kv-$workload-$env-$azureRegion'
$adminPassword = 'adminPassword'
$secretValue = 'abc123!'

az keyvault secret set -n $secretName --vault-name $keyVaultName --value $secretValue
```

#### Azure User Assigned Managed Identity

The application deployment uses an Azure User Assigned Managed Identity to extract the wildcard certificate during the deployment of the Azure Application Gateway. This identity needs access rights over the secrets stored within the Azure Key Vault.

##### Create the Azure User Assigned Managed Identity

To create the Azure User Assigned Managed Identity, open a terminal and run the following command using the appropriate variables:

```powershell
$workload = 'Name of the workload'
$env = 'Name of the environment'
$azureRegion = 'Name of the Azure Region'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'
$managedIdentityName = 'id-$workload-$env-$azureRegion'

az identity create -n $managedIdentityName -g $resourceGroupName
```

For example:

```powershell
$workload = 'hdsr'
$env = 'prod'
$azureRegion = 'eastus'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'
$managedIdentityName = 'id-$workload-$env-$azureRegion'

az identity create -n $managedIdentityName -g $resourceGroupName
```

##### Assign the Azure User Assigned Managed Identity to an Azure Key Vault Access Policy

To assign the Azure User Assigned Managed Identity to an Azure Key Vault Access Policy, open a terminal and run the following command using the appropriate variables:

```powershell
$workload = 'Name of the workload'
$env = 'Name of the environment'
$azureRegion = 'Name of the Azure Region'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'
$keyValutName = 'kv-$workload-$env-$azureRegion'
$managedIdentityName = 'id-$workload-$env-$azureRegion'

$managedIdentityPrincipalId=az identity show -g $resourceGroupName -n $managedIdentityName --query principalId

az keyvault set-policy -g $resourceGroupName -n $keyVaultName --object-id $managedIdentityPrincipalId--secret-permissions get
```

For example:

```powershell
$workload = 'hdsr'
$env = 'prod'
$azureRegion = 'eastus'
$resourceGroupName = 'rg-$workload-$env-$azureRegion-core'
$keyValutName = 'kv-$workload-$env-$azureRegion'
$managedIdentityName = 'id-$workload-$env-$azureRegion'

$managedIdentityPrincipalId=az identity show -g $resourceGroupName -n $managedIdentityName --query principalId

az keyvault set-policy -g $resourceGroupName -n $keyVaultName --object-id $managedIdentityPrincipalId--secret-permissions get
```

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
