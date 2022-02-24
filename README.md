# cop2940

TODO: Insert text here...


## Prerequisites

TODO: Insert text here...

### Azure Setup

TODO: Insert text here...

#### Resource Groups

The application deployment uses two Azure Resource Groups (core and app). The 'core' Resource Group is created prior to the deployment, and the 'app' Resource Group is created during the deployment. Prior to creating the 'core' Resource Group it is necessary to define a series of parameters that will be used throughout the deployment. These parameters are used to build resource names and are used in any AZ CLI script, PowerShell script, ARM Template, and YAML workflow to deploy the infrastructure and application. The following parameters must be defined:

- `workload` - defines the name of the workload to be deployed (e.g. `helpdesk`, `hdsr`)
- `env` - defines the name of the environment to be deployed to (e.g. `prod`, `dev`, or `test`)
- `azureRegion` - defines the name of the Azure Region to be deployed to (e.g. `eastus`, `eastus2`)

```azcli
az group create -n rg-${workload}-${env}-${azureRegion}-core
```


Key Vault

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
