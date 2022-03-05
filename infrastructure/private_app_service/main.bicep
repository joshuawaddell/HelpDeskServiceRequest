// Parameters
//////////////////////////////////////////////////
@description('The name of the existing Key Vault Secret for the admin password.')
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The name of the existing Application Gateway Managed Identity.')
param applicationGatewayManagedIdentityName string

@description('The name of the existing Application Gateway Managed Identity Resource Group.')
param applicationGatewayManagedIdentityResourceGroupName string

@description('The selected Azure region for deployment.')
param azureRegion string

@description('The name of the existing Key Vault Secret for the certificate.')
param certificate string

@description('The environment name.')
param env string

@description('The name of the existing Azure Key Vault.')
param keyVaultName string

@description('The name of the existing Azure Key Vault Resource Group.')
param keyVaultResourceGroupName string

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The value for Root Domain Name.')
param rootDomainName string

@description('The name of the SSL Certificate.')
param sslCertificateName string

@description('The name of the application workload.')
param workload string

// Global Variables
//////////////////////////////////////////////////
var applicationGatewayName = 'appgw-${workload}-${env}-${azureRegion}'
var applicationGatewayPublicIpAddressName = 'pip-${workload}-${env}-${azureRegion}'
var applicationGatewaySubnetName = 'snet-${workload}-${env}-${azureRegion}-applicationGateway'
var applicationGatewaySubnetPrefix = '10.0.0.0/24'
var applicationInsightsName = 'appinsights-${workload}-${env}-${azureRegion}'
var appServiceFqdn = replace('app-${workload}-${env}-${azureRegion}.azurewebsites.net', '-', '')
var appServiceHostName = 'hdsr.${rootDomainName}'
var appServiceName = replace('app-${workload}-${env}-${azureRegion}', '-', '')
var appServicePlanName = 'plan-${workload}-${env}-${azureRegion}'
var appServicePrivateDnsZoneName = 'privatelink.azurewebsites.net'
var appServicePrivateEndpointName = 'pl-${workload}-${env}-${azureRegion}-appService'
var azureSQLprivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var containerInstanceSubnetName = 'snet-${workload}-${env}-${azureRegion}-containerInstance'
var containerInstanceSubnetPrefix = '10.0.30.0/24'
var logAnalyticsWorkspaceName = 'log-${workload}-${env}-${azureRegion}'
var privateEndpointSubnetName = 'snet-${workload}-${env}-${azureRegion}-privateEndpoint'
var privateEndpointSubnetPrefix = '10.0.10.0/24'
var sqlDatabaseName = 'sqldb-${workload}-${env}-${azureRegion}'
var sqlServerName = 'sql-${workload}-${env}-${azureRegion}'
var sslCertificateDataPassword = ''
var sqlServerPrivateEndpointName = 'pl-${workload}-${env}-${azureRegion}-sqlServer'
var virtualNetworkName = 'vnet-${workload}-${env}-${azureRegion}'
var virtualnetworkPrefix = '10.0.0.0/16'
var vnetIntegrationSubnetName = 'snet-${workload}-${env}-${azureRegion}-vnetintegration'
var vnetIntegrationSubnetPrefix = '10.0.20.0/24'

// Existing Resource - Key Vault
//////////////////////////////////////////////////
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  scope: resourceGroup(keyVaultResourceGroupName)
  name: keyVaultName
}

// Existing Resource - Managed Identity
//////////////////////////////////////////////////
resource applicationGatewayManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  scope: resourceGroup(applicationGatewayManagedIdentityResourceGroupName)
  name: applicationGatewayManagedIdentityName
}

// Module - Log Analytics Workspace
//////////////////////////////////////////////////
module logAnalyticsModule './log_analytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

// Module - Application Insights
//////////////////////////////////////////////////
module applicationInsightsModule './application_insights.bicep' = {
  name: 'applicationInsightsDeployment'
  params: {
    applicationInsightsName: applicationInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}

// Module - Virtual Network
//////////////////////////////////////////////////
module virtualNetworkModule './virtual_network.bicep' = {
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
module privateDnsModule './private_dns_zone.bicep' = {
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
module sqlModule './sql.bicep' = {
  name: 'sqlDeployment'
  params: {
    adminPassword: keyVault.getSecret(adminPassword)
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
module appServicePlanModule './app_service_plan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    appServicePlanName: appServicePlanName
    location: location
  }
}

// Module - App Service
//////////////////////////////////////////////////
module appServiceModule './app_service.bicep' = {
  name: 'appServiceDeployment'
  params: {
    adminPassword: keyVault.getSecret(adminPassword)
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
module applicationGatewayModule './application_gateway.bicep' = {
  name: 'applicationGatewayDeployment'
  dependsOn: [
    appServiceModule
  ]
  params: {
    applicationGatewayManagedIdentityId: applicationGatewayManagedIdentity.id
    applicationGatewayName: applicationGatewayName
    applicationGatewayPublicIpAddressName: applicationGatewayPublicIpAddressName
    applicationGatewaySubnetId: virtualNetworkModule.outputs.applicationGatewaySubnetId
    appServiceFqdn: appServiceFqdn
    appServiceHostName: appServiceHostName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    sslCertificateData: keyVault.getSecret(certificate)
    sslCertificateDataPassword: sslCertificateDataPassword
    sslCertificateName: sslCertificateName
  }
}
