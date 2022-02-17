// Parameters
//////////////////////////////////////////////////
@description('The name of the Application Gateway Subnet.')
param applicationGatewaySubnetName string

@description('The address prefix of the Application Gateway Subnet.')
param applicationGatewaySubnetPrefix string

@description('The name of the Container Instance Subnet.')
param containerInstanceSubnetName string

@description('The address prefix of the Container Instance Subnet.')
param containerInstanceSubnetPrefix string

@description('The location for all resources.')
param location string

@description('The resource ID of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('The name of the Private Endpoint Subnet.')
param privateEndpointSubnetName string

@description('The address prefix of the Private Endpoint Subnet.')
param privateEndpointSubnetPrefix string

@description('The name of the Virtual Network.')
param virtualNetworkName string

@description('The address prefix of the Virtual Network.')
param virtualnetworkPrefix string

@description('The name of the VNET Integration Subnet.')
param vnetIntegrationSubnetName string

@description('The address prefix of the VNET Integration Subnet.')
param vnetIntegrationSubnetPrefix string

// Variables
//////////////////////////////////////////////////
@description('List of Azure Tags for resources.')
var tags = {
  environment: 'production'
  function: 'networking'
}

// Resource - Virtual Network
//////////////////////////////////////////////////
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualnetworkPrefix
      ]
    }
    subnets: [
      {
        name: applicationGatewaySubnetName
        properties: {
          addressPrefix: applicationGatewaySubnetPrefix
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: vnetIntegrationSubnetName
        properties: {
          addressPrefix: vnetIntegrationSubnetPrefix
          delegations: [
            {
              name: 'appServicePlanDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: containerInstanceSubnetName
        properties: {
          addressPrefix: containerInstanceSubnetPrefix
        }
      }
    ]
  }
}

// Resource - Virtual Network - Diagnostic Settings
//////////////////////////////////////////////////
resource virtualNetworkDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: virtualNetwork
  name: '${virtualNetwork.name}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'VMProtectionAlerts'
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

// Outputs
//////////////////////////////////////////////////
@description('The resource ID of the Application Gateway subnet.')
output applicationGatewaySubnetId string = virtualNetwork.properties.subnets[0].id

@description('The resource ID of the Private Endpoint subnet.')
output privateEndpointSubnetId string = virtualNetwork.properties.subnets[1].id

@description('The resource ID of the Virtual Network.')
output virtualNetworkId string = virtualNetwork.id

@description('The resource ID of the VNET Integration subnet.')
output vnetIntegrationSubnetId string = virtualNetwork.properties.subnets[2].id
