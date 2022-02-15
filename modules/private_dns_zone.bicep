// Parameters
//////////////////////////////////////////////////
@description('The name of the Azure App Service Private DNS Zone.')
param appServicePrivateDnsZoneName string

@description('The name of the Azure SQL Private DNS Zone.')
param azureSQLPrivateDnsZoneName string

@description('The resource ID of the Virtual Network.')
param virtualNetworkId string

@description('The name of the Virtual Network.')
param virtualNetworkName string

// Variables
//////////////////////////////////////////////////
@description('List of Azure Tags for resources.')
var tags = {
  environment: 'production'
  function: 'networking'
}

// Resource - Private Dns Zone - Privatelink.Azurewebsites.Net
//////////////////////////////////////////////////
resource appServicePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: appServicePrivateDnsZoneName
  location: 'global'
  tags: tags
}

// Resource - Private Dns Zone - Privatelink.Database.Windows.Net
//////////////////////////////////////////////////
resource azureSQLPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: azureSQLPrivateDnsZoneName
  location: 'global'
  tags: tags
}

// Resource Virtual Network Link - Privatelink.Azurewebsites.Net To Virtual Network
//////////////////////////////////////////////////
resource vnetLink01 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/${virtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}


// Resource Virtual Network Link - Privatelink.Database.Windows.Net To Virtual Network 
//////////////////////////////////////////////////
resource vnetLink11 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${azureSQLPrivateDnsZone.name}/${virtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

// Outputs
//////////////////////////////////////////////////
@description('The resource ID of the Azure SQL Private DNS Zone.')
output azureSqlPrivateDnsZoneId string = azureSQLPrivateDnsZone.id

@description('The resource ID of the App Service Private DNS Zone.')
output appServicePrivateDnsZoneId string = appServicePrivateDnsZone.id
