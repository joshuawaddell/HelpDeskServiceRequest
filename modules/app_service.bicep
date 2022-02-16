// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
@secure()
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The connection string of the Application Insights instance.')
param applicationInsightsConnectionString string

@description('The instrumentation key of th Application Insights instance.')
param applicationInsightsInstrumentationKey string

@description('The name of the App Service.')
param appServiceName string

@description('The resource ID of the App Service Plan.')
param appServicePlanId string

@description('The resource ID of the App Service Private Dns Zone.')
param appServicePrivateDnsZoneId string

@description('The name of the App Service Private Endpoint.')
param appServicePrivateEndpointName string

@description('The location for all resources.')
param location string

@description('The resource ID of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('The resource ID of the Private Endpoint Subnet.')
param privateEndpointSubnetId string

@description('The name of the Sql Database.')
param sqlDatabaseName string

@description('The FQDN of the Sql Server.')
param sqlServerFQDN string

@description('The resource ID of the Virtual Network Integration Subnet.')
param vnetIntegrationSubnetId string

// Variables
//////////////////////////////////////////////////
@description('List of Azure Tags for resources.')
var tags = {
  environment: 'production'
  function: 'app services'
}

// Resource - App Service
//////////////////////////////////////////////////
resource appService 'Microsoft.Web/sites@2020-12-01' = {
  name: appServiceName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true

    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'DefaultSqlConnectionSqlConnectionString'
          value: 'Data Source=tcp:${sqlServerFQDN},1433;Initial Catalog=${sqlDatabaseName};User Id=${adminUserName}@${sqlServerFQDN};Password=${adminPassword};'
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

// Resource - App Service - Logging
//////////////////////////////////////////////////
resource appServiceLogs 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${appService.name}/logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    detailedErrorMessages: {
      enabled: true
    }
    failedRequestsTracing: {
      enabled: true
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

// Resource - Private Endpoint - App service
//////////////////////////////////////////////////
resource appServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: appServicePrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: appServicePrivateEndpointName
        properties: {
          privateLinkServiceId: appService.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

// Resource - Prviate Endpoint Dns Group - Private Endpoint
//////////////////////////////////////////////////
resource appServicePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${appServicePrivateEndpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: appServicePrivateDnsZoneId
        }
      }
    ]
  }
}
