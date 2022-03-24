@description('The location into which regionally scoped resources should be deployed.')
param location string

@description('The name of the API Management service instance.')
param apiManagementServiceName string

var readerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // as per https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#:~:text=acdd72a7-3385-48ef-bd42-f606fba81ae7
var managedIdentityName = 'ApiManagementReader'
var deploymentScriptName = 'ReadApiManagementService'

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource roleAssignmentReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: apiManagementService
  name: guid(apiManagementService.id, managedIdentity.id, readerRoleDefinitionId)
  properties: {
    roleDefinitionId: readerRoleDefinitionId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    roleAssignmentReader
  ]
  properties: {
    azCliVersion: '2.34.0'
    scriptContent: loadTextContent('../scripts/api-management-get-domain-ownership-identifier.sh')
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT4H'
    environmentVariables: [
      {
        name: 'subscriptionId'
        value: subscription().subscriptionId
      }
    ]
  }
}

output domainOwnershipIdentifier string = deploymentScript.properties.outputs.domainOwnershipIdentifier
