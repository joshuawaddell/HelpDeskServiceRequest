// Parameters
//////////////////////////////////////////////////
@description('The ID of the Application Gateway Managed Identity.')
param applicationGatewayManagedIdentityId string

@description('The name of the Application Gateway.')
param applicationGatewayName string

@description('The name of the Application Gateway Public IP Address.')
param applicationGatewayPublicIpAddressName string

@description('The ID of the Application Gateway Subnet')
param applicationGatewaySubnetId string

@description('The FQDN of the App Service.')
param appServiceFqdn string

@description('The host name of the App Service.')
param appServiceHostName string

@description('The location for all resources.')
param location string

@description('The resource ID of the Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('The data of the SSL Certificate (stored in KeyVault.)')
@secure()
param sslCertificateData string

@description('The password of the SSL Certificate (stored in KeyVault.)')
param sslCertificateDataPassword string

@description('The name of the SSL Certificate (stored in KeyVault).')
param sslCertificateName string

// Variables
//////////////////////////////////////////////////
@description('The configuration settings of the App Service.')
var appServiceConfig = {
  configuration: {
    backendPoolName: 'backendPool-appService'
    fqdn: appServiceFqdn
    healthProbeName: 'probe-appService'
    hostName: appServiceHostName
    httpListenerName: 'listener-http-appService'
    httpSettingName: 'httpsetting-appService'
    httpsListenerName: 'listener-https-appService'
    redirectionConfigName: 'redirectionconfig-appService'
    redirectionRoutingRuleName: 'routingrule-redirection-appService'
    routingRuleName: 'routingrule-appService'
  }
}
@description('List of Azure Tags for resources.')
var tags = {
  environment: 'production'
  function: 'networking'
}

// Resource - Public Ip Address - Application Gateway
//////////////////////////////////////////////////
resource applicationGatewayPublicIpAddress 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: applicationGatewayPublicIpAddressName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

// Resource - Public Ip Address - Diagnostic Settings - Application Gateway
//////////////////////////////////////////////////
resource applicationGatewayPublicIpAddressDiagnostics 'Microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: applicationGatewayPublicIpAddress
  name: '${applicationGatewayPublicIpAddress.name}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: true
      }
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: true
      }
      {
        category: 'DDoSMitigationReports'
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

// Resource - Application Gateway
//////////////////////////////////////////////////
resource applicationGateway 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: applicationGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    enableHttp2: false
    sslCertificates: [
      {
        name: sslCertificateName
        properties: {
          data: sslCertificateData
          password: sslCertificateDataPassword
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIPConfig'
        properties: {
          subnet: {
            id: applicationGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIpConfiguration'
        properties: {
          publicIPAddress: {
            id: applicationGatewayPublicIpAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: appServiceConfig.configuration.backendPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: appServiceConfig.configuration.fqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appServiceConfig.configuration.httpSettingName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: appServiceConfig.configuration.httpListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIpConfiguration')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_80')
          }
          protocol: 'Http'
          hostName: appServiceConfig.configuration.hostName
          requireServerNameIndication: false
        }
      }
      {
        name: appServiceConfig.configuration.httpsListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIpConfiguration')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, sslCertificateName)
          }
          hostName: appServiceConfig.configuration.hostName
          requireServerNameIndication: false
        }
      }
    ]
    redirectConfigurations: [
      {
        name: appServiceConfig.configuration.redirectionConfigName
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, appServiceConfig.configuration.httpsListenerName)
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: appServiceConfig.configuration.routingRuleName
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, appServiceConfig.configuration.httpsListenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, appServiceConfig.configuration.backendPoolName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, appServiceConfig.configuration.httpSettingName)
          }
        }
      }
      {
        name: appServiceConfig.configuration.redirectionRoutingRuleName
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, appServiceConfig.configuration.httpListenerName)
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, appServiceConfig.configuration.redirectionConfigName)
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.1'
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${applicationGatewayManagedIdentityId}': {}
    }
  }
}

// Resource - Application Gateway - Diagnostic Settings
//////////////////////////////////////////////////
resource applicationGatewayDiagnostics 'Microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: applicationGateway
  name: '${applicationGateway.name}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
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
