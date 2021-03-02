// Based on https://github.com/johndowns/frontdoor-multi-domain-arm/blob/main/template.json

param frontDoorName string
param app1BackendUrl string
param app2BackendUrl string
param customers array

var frontDoorBackendPoolApp1Name = 'backend-pool-app-1'
var frontDoorBackendPoolApp2Name = 'backend-pool-app-2'

// Assemble an object representing the default frontend for the Front Door instance.
var frontDoorFrontendDefaultName = 'frontend-default'
var frontDoorFrontendDefault = {
  name: frontDoorFrontendDefaultName
  properties: {
    hostName: '${frontDoorName}.azurefd.net'
    sessionAffinityEnabledState: 'Disabled'
    sessionAffinityTtlSeconds: 0
  }
}

// Assemble an array of frontends for each customer's hostnames.
var frontDoorFrontendNamesApp1 = [for customer in customers:
  'frontend-app1-${customer.customerId}'
]

// TODO need more here
