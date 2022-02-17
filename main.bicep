// Parameters
//////////////////////////////////////////////////
@description('The name of the admin user.')
param adminUserName string

@description('The selected Azure region for deployment.')
param azureRegion string = 'eus'

@description('The environment name.')
@allowed([
  'prod'
  'dev'
  'test'
])
param env string = 'prod'

@description('The instance identifier')
param instance string = '001'

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The value for Root Domain Name.')
param rootDomainName string = 'joshuawaddell.cloud'

@description('The name of the SSL Certificate.')
param sslCertificateName string = 'joshuawaddell.cloud'

@description('The name of the application workload.')
param workload string = 'cop2940'

// Global Variables
//////////////////////////////////////////////////
var applicationGatewayManagedIdentityName = 'id-${workload}-${env}-${azureRegion}-applicationGateway'
var applicationGatewayName = 'appgw-${workload}-${env}-${azureRegion}-${instance}'
var applicationGatewayPublicIpAddressName = 'pip-${workload}-${env}-${azureRegion}-${instance}'
var applicationGatewaySubnetName = 'snet-${workload}-${env}-${azureRegion}-applicationGateway'
var applicationGatewaySubnetPrefix = '10.0.0.0/24'
var applicationInsightsName = 'appinsights-${workload}-${env}-${azureRegion}-${instance}'
var appServiceFqdn = replace('app-${workload}-${env}-${azureRegion}-${instance}.azurewebsites.net', '-', '')
var appServiceHostName = 'hdsr.${rootDomainName}'
var appServiceName = replace('app-${workload}-${env}-${azureRegion}-${instance}', '-', '')
var appServicePlanName = 'plan-${workload}-${env}-${azureRegion}-${instance}'
var appServicePrivateDnsZoneName = 'privatelink.azurewebsites.net'
var appServicePrivateEndpointName = 'pl-${workload}-${env}-${azureRegion}-appService'
var azureSQLprivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var containerInstanceSubnetName = 'snet-${workload}-${env}-${azureRegion}-containerInstance'
var containerInstanceSubnetPrefix = '10.0.30.0/24'
var keyVaultName = 'kv-${workload}-${env}-${azureRegion}-${instance}'
var logAnalyticsWorkspaceName = 'log-${workload}-${env}-${azureRegion}-${instance}'
var privateEndpointSubnetName = 'snet-${workload}-${env}-${azureRegion}-privateEndpoint'
var privateEndpointSubnetPrefix = '10.0.10.0/24'
var resourceGroupName = 'rg-${workload}-${env}-${azureRegion}-production'
var sqlDatabaseName = 'sqldb-${workload}-${env}-${azureRegion}-${instance}'
var sqlServerName = 'sql-${workload}-${env}-${azureRegion}-${instance}'
var sslCertificateDataPassword = ''
var sqlServerPrivateEndpointName = 'pl-${workload}-${env}-${azureRegion}-sqlServer'
var virtualNetworkName = 'vnet-${workload}-${env}-${azureRegion}-${instance}'
var virtualnetworkPrefix = '10.0.0.0/16'
var vnetIntegrationSubnetName = 'snet-${workload}-${env}-${azureRegion}-vnetintegration'
var vnetIntegrationSubnetPrefix = '10.0.20.0/24'

// Existing Resource - Key Vault
//////////////////////////////////////////////////
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: keyVaultName
}

// Existing Resource - Managed Identity
//////////////////////////////////////////////////
resource applicationGatewayManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  scope: resourceGroup(resourceGroupName)
  name: applicationGatewayManagedIdentityName
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
  name: 'virtualNetworkDeployment'
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

// Module - Application Gateway
//////////////////////////////////////////////////
module applicationGateway './modules/application_gateway.bicep' = {
  name: 'applicationGatewayDeployment'
  params: {
    applicationGatewayManagedIdentityId: applicationGatewayManagedIdentity.id
    applicationGatewayName: applicationGatewayName
    applicationGatewayPublicIpAddressName: applicationGatewayPublicIpAddressName
    applicationGatewaySubnetId: virtualNetworkModule.outputs.applicationGatewaySubnetId
    appServiceFqdn: appServiceFqdn
    appServiceHostName: appServiceHostName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    sslCertificateData: keyVault.getSecret('certificate')
    sslCertificateDataPassword: sslCertificateDataPassword
    sslCertificateName: sslCertificateName
  }
}
