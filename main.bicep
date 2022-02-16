// Parameters
//////////////////////////////////////////////////
@description('The name of the admin user.')
param adminUserName string

@description('The selected Azure region for deployment.')
param azureRegion string = 'eastus'

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The name of the application workload.')
param workload string = 'cop2940'

// Global Variables
//////////////////////////////////////////////////
var applicationGatewaySubnetName = 'snet-${workload}-${azureRegion}-applicationGateway'
var applicationGatewaySubnetPrefix = '10.0.0.0/24'
var applicationInsightsName = 'appinsights-${workload}-${azureRegion}-001'
var appServiceName = 'app-${workload}-${azureRegion}-001'
var appServicePlanName = 'plan-${workload}-${azureRegion}-001'
var appServicePrivateDnsZoneName = 'privatelink.azurewebsites.net'
var appServicePrivateEndpointName = 'pl-${workload}-${azureRegion}-appService'
var azureSQLprivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var containerInstanceSubnetName = 'snet-${workload}-${azureRegion}-containerInstance'
var containerInstanceSubnetPrefix = '10.0.30.0/24'
var keyVaultName = 'kv-${workload}-${azureRegion}-001'
var logAnalyticsWorkspaceName = 'log-${workload}-${azureRegion}-001'
var privateEndpointSubnetName = 'snet-${workload}-${azureRegion}-privateEndpoint'
var privateEndpointSubnetPrefix = '10.0.10.0/24'
var resourceGroupName = 'rg-${workload}-${azureRegion}-production'
var sqlDatabaseName = 'sqldb-${workload}-${azureRegion}-001'
var sqlServerName = 'sql-${workload}-${azureRegion}-001'
var sqlServerPrivateEndpointName = 'pl-${workload}-${azureRegion}-sqlServer'
var virtualNetworkName = 'vnet-${workload}-${azureRegion}-001'
var virtualnetworkPrefix = '10.0.0.0/16'
var vnetIntegrationSubnetName = 'snet-${workload}-${azureRegion}-vnetintegration'
var vnetIntegrationSubnetPrefix = '10.0.20.0/24'

// Existing Resource - Key Vault
//////////////////////////////////////////////////
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: keyVaultName
}

// Module - Log Analytics Workspace
//////////////////////////////////////////////////
module logAnalyticsModule './modules/log_analytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

// Module - Application Insights
//////////////////////////////////////////////////
module applicationInsightsModule './modules/application_insights.bicep' = {
  name: 'applicationInsightsDeployment'
  params: {
    applicationInsightsName: applicationInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}

// Module - Virtual Network
//////////////////////////////////////////////////
module virtualNetworkModule './modules/virtual_network.bicep' = {
  name: 'virtualNetwork001Deployment'
  params: {
    applicationGatewaySubnetName: applicationGatewaySubnetName
    applicationGatewaySubnetPrefix: applicationGatewaySubnetPrefix
    containerInstanceSubnetName: containerInstanceSubnetName
    containerInstanceSubnetPrefix: containerInstanceSubnetPrefix
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    privateEndpointSubnetName: privateEndpointSubnetName
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
    virtualNetworkName: virtualNetworkName
    virtualnetworkPrefix: virtualnetworkPrefix
    vnetIntegrationSubnetName: vnetIntegrationSubnetName
    vnetIntegrationSubnetPrefix: vnetIntegrationSubnetPrefix
  }
}

// Module - Private Dns
//////////////////////////////////////////////////
module privateDnsModule './modules/private_dns_zone.bicep' = {
  name: 'privateDnsDeployment'
  params: {
    appServicePrivateDnsZoneName: appServicePrivateDnsZoneName
    azureSQLPrivateDnsZoneName: azureSQLprivateDnsZoneName
    virtualNetworkId: virtualNetworkModule.outputs.virtualNetworkId
    virtualNetworkName: virtualNetworkName
  }
}

// Module - SQL
//////////////////////////////////////////////////
module sqlModule './modules/sql.bicep' = {
  name: 'sqlDeployment'
  params: {
    adminPassword: keyVault.getSecret('adminPassword')
    adminUserName: adminUserName
    azureSqlPrivateDnsZoneId: privateDnsModule.outputs.azureSqlPrivateDnsZoneId
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    privateEndpointSubnetId: virtualNetworkModule.outputs.privateEndpointSubnetId
    sqlDatabaseName: sqlDatabaseName
    sqlServerName: sqlServerName
    sqlServerPrivateEndpointName: sqlServerPrivateEndpointName
  }
}

// Module - App Service Plan
//////////////////////////////////////////////////
module appServicePlanModule './modules/app_service_plan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    appServicePlanName: appServicePlanName
    location: location
  }
}

// Module - App Service
//////////////////////////////////////////////////
module appService './modules/app_service.bicep' = {
  name: 'appServiceDeployment'
  params: {
    adminPassword: keyVault.getSecret('adminPassword')
    adminUserName: adminUserName
    applicationInsightsConnectionString: applicationInsightsModule.outputs.applicationInsightsConnectionString
    applicationInsightsInstrumentationKey: applicationInsightsModule.outputs.applicationInsightsInstrumentationKey    
    appServiceName: appServiceName
    appServicePlanId: appServicePlanModule.outputs.appServicePlanId
    appServicePrivateDnsZoneId: privateDnsModule.outputs.appServicePrivateDnsZoneId
    appServicePrivateEndpointName: appServicePrivateEndpointName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    privateEndpointSubnetId: virtualNetworkModule.outputs.privateEndpointSubnetId
    sqlDatabaseName: sqlDatabaseName
    sqlServerFQDN: sqlModule.outputs.sqlServerFQDN
    vnetIntegrationSubnetId: virtualNetworkModule.outputs.vnetIntegrationSubnetId
  }
}
