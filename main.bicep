// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
param adminPassword string

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
// Resources
// Log Analytics
var logAnalyticsWorkspaceName = 'log-${workload}-${azureRegion}-001'

// Application Insights
var applicationInsightsName = 'appinsights-${workload}-${azureRegion}-001'

// Virtual Network
var applicationGatewaySubnetName = 'snet-${workload}-${azureRegion}-applicationGateway'
var applicationGatewaySubnetPrefix = '10.0.0.0/24'
var privateEndpointSubnetName = 'snet-${workload}-${azureRegion}-privateEndpoint'
var privateEndpointSubnetPrefix = '10.0.10.0/24'
var virtualNetworkName = 'vnet-${workload}-${azureRegion}-001'
var virtualnetworkPrefix = '10.0.0.0/16'
var vnetIntegrationSubnetName = 'snet-${workload}-${azureRegion}-vnetintegration'
var vnetIntegrationSubnetPrefix = '10.0.20.0/24'

// Private DNS
var appServicePrivateDnsZoneName = 'privatelink.azurewebsites.net'
var azureSQLprivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'

// SQL
var sqlDatabaseName = 'sqldb-${workload}-${azureRegion}-001'
var sqlServerName = 'sql-${workload}-${azureRegion}-001'
var sqlServerPrivateEndpointName = 'pl-${workload}-${azureRegion}-sqlServer'

// App Service Plan
var appServicePlanName = 'plan-${workload}-${azureRegion}-001'


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
    adminPassword: adminPassword
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
