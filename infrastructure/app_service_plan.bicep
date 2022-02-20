// Parameters
//////////////////////////////////////////////////
@description('The location for all resources.')
param location string

@description('The name of the App Service Plan.')
param appServicePlanName string

// Variables
//////////////////////////////////////////////////
@description('List of Azure Tags for resources.')
var tags = {
  environment: 'production'
  function: 'app services'
}

// Resource - App Service Plan
//////////////////////////////////////////////////
resource appServicePlan 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
  }
  properties: {
    reserved: true
  }
}

// Outputs
//////////////////////////////////////////////////
@description('The resource ID of the App Service Plan.')
output appServicePlanId string = appServicePlan.id
