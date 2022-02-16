// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
@secure()
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The resource ID of the Azure Sql Private Dns Zone.')
param azureSqlPrivateDnsZoneId string

@description('The location for all resources.')
param location string

@description('The resource ID of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('The resource ID of the Private Endpoint Subnet.')
param privateEndpointSubnetId string

@description('The name of the Sql Database.')
param sqlDatabaseName string

@description('The name of the Sql Server Private Endpoint.')
param sqlServerPrivateEndpointName string

@description('The name of the Sql Server.')
param sqlServerName string

// Variables
//////////////////////////////////////////////////
@description('List of Azure Tags for resources.')
var tags = {
  environment: 'production'
  function: 'sql'
  costCenter: 'it'
}

// Resource - Sql Server
//////////////////////////////////////////////////
resource sqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Disabled'
    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword
    version: '12.0'
  }
}

// Resource - Sql Database
//////////////////////////////////////////////////
resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 40
  }
  properties: {
    collation: 'Sql_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
    zoneRedundant: true
    autoPauseDelay: 60
    minCapacity: 5
  }
}

// Resource - Sql Database - Diagnostic Settings
//////////////////////////////////////////////////
resource sqlDatabaseDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: sqlDatabase
  name: '${sqlDatabase.name}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
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

// Resource - Private Endpoint - Sql Server
//////////////////////////////////////////////////
resource sqlServerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: sqlServerPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: sqlServerPrivateEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Resource - Prviate Endpoint Dns Group - Private Endpoint
//////////////////////////////////////////////////
resource sqlprivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${sqlServerPrivateEndpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: azureSqlPrivateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
//////////////////////////////////////////////////
@description('The FQDN of the SQL Server.')
output sqlServerFQDN string = sqlServer.properties.fullyQualifiedDomainName
