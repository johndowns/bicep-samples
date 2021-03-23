@description('The region into which the Azure Storage resources should be deployed.')
param location string

@description('TODO')
param storageAccountName string

@description('TODO')
param containerName string

@description('TODO')
@minValue(1)
param containerImmutabilityPeriodSinceCreationInDays int

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // TODO parameterize
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot' // TODO parameterize
  }

  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = if (containerName != '') {
  name: containerName
  parent: storageAccount::blobService
  properties: {
    publicAccess: 'None'
  }

  resource immutabilityPolicy 'immutabilityPolicies' = {
    name: 'default'
    properties: {
      immutabilityPeriodSinceCreationInDays: containerImmutabilityPeriodSinceCreationInDays
      allowProtectedAppendWrites: false
    }
  }
}

output storageAccountName string = storageAccount.name
