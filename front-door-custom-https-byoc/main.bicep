param frontDoorName string
param backendAddress string
param customDomainName string
param certificateKeyVaultId string // The resource ID of the Key Vault containing the secret, e.g. /subscriptions/{subscriptionId}/resourcegroups/{resourceGroup}/providers/Microsoft.KeyVault/vaults/{vault}.
param certificateSecretName string // The name of the Key Vault secret that contains the encoded X.509 certificate; this is just a simple name, e.g. "mycertificate".
param certificateSecretVersion string = '' // A specific version of the secret to use. If you omit this, I *think* Front Door uses the most recent version. It's usually best practice to include this if you can though.

var frontEndEndpointDefaultName = 'frontEndEndpointDefault'
var frontEndEndpointCustomName = 'frontEndEndpointCustom'
var loadBalancingSettingsName = 'loadBalancingSettings'
var healthProbeSettingsName = 'healthProbeSettings'
var routingRuleName = 'routingRule'
var backendPoolName = 'backendPool'

resource frontDoor 'Microsoft.Network/frontDoors@2020-01-01' = {
  name: frontDoorName
  location: 'global'
  properties: {
    enabledState: 'Enabled'

    frontendEndpoints: [
      {
        name: frontEndEndpointDefaultName
        properties: {
          hostName: concat(frontDoorName, '.azurefd.net')
          sessionAffinityEnabledState: 'Disabled'
        }
      }
      {
        name: frontEndEndpointCustomName
        properties: {
          hostName: customDomainName
          sessionAffinityEnabledState: 'Disabled'
        }
      }
    ]

    loadBalancingSettings: [
      {
        name: loadBalancingSettingsName
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]

    healthProbeSettings: [
      {
        name: healthProbeSettingsName
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 120
        }
      }
    ]

    backendPools: [
      {
        name: backendPoolName
        properties: {
          backends: [
            {
              address: backendAddress
              backendHostHeader: backendAddress
              httpPort: 80
              httpsPort: 443
              weight: 50
              priority: 1
              enabledState: 'Enabled'
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, loadBalancingSettingsName)
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, healthProbeSettingsName)
          }
        }
      }
    ]

    routingRules: [
      {
        name: routingRuleName
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontEndEndpoints', frontDoorName, frontEndEndpointDefaultName)
            }
            {
              id: resourceId('Microsoft.Network/frontDoors/frontEndEndpoints', frontDoorName, frontEndEndpointCustomName)
            }
          ]
          acceptedProtocols: [
            'Http'
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'MatchRequest'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backEndPools', frontDoorName, backendPoolName)
            }
          }
          enabledState: 'Enabled'
        }
      }
    ]
  }
}

// Enable a Front Door-managed certificate on the custom domain.
resource customDomainHttpsConfiguration 'Microsoft.Network/frontDoors/frontendEndpoints/customHttpsConfiguration@2020-07-01' = {
  name: '${frontDoorName}/${frontEndEndpointCustomName}/default'
  dependsOn: [
    frontDoor
  ]
  properties: {
    protocolType: 'ServerNameIndication'
    certificateSource: 'AzureKeyVault'
    keyVaultCertificateSourceParameters: {
      vault: {
        id: certificateKeyVaultId
      }
      secretName: certificateSecretName
      secretVersion: (certificateSecretVersion == '') ? null : certificateSecretVersion
    }
    minimumTlsVersion: '1.2'
  }
}
