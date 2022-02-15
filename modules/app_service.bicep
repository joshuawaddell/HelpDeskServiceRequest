// Parameters
//////////////////////////////////////////////////
@description('The name of the App Service.')
param appServiceName string

@description('The resource ID of the App Service Plan.')
param appServicePlanId string

@description('The location for all resources.')
param location string

@description('The resource ID of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('The resource ID of the Virtual Network Integration Subnet.')
param vnetIntegrationSubnetId string

// Variables
//////////////////////////////////////////////////
@description('List of Azure Tags for resources.')
var tags = {
  environment: 'production'
  function: 'app services'
}

// Resource - App Service - Inspector Gadget
//////////////////////////////////////////////////
resource appService 'Microsoft.Web/sites@2020-12-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: 'container'
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: false

    siteConfig: {
      linuxFxVersion: inspectorGadgetDockerImage
      appSettings: [
        {
          name: 'DefaultSqlConnectionSqlConnectionString'
          value: 'Data Source=tcp:${inspectorGadgetSqlServerFQDN},1433;Initial Catalog=${inspectorGadgetSqlDatabaseName};User Id=${adminUserName}@${inspectorGadgetSqlServerFQDN};Password=${adminPassword};'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
      ]
    }
  }
}

// Resource - App Service - Networking
//////////////////////////////////////////////////
resource appServiceNetworking 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${appService.name}/virtualNetwork'
  properties: {
    subnetResourceId: vnetIntegrationSubnetId
    swiftSupported: true
  }
}

// Resource - App Service - Diagnostic Settings
//////////////////////////////////////////////////
resource appServiceDiagnostics 'Microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: appService
  name: '${appService.name}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AllLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
