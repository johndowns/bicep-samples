@description('The region into which the Azure Storage resources should be deployed.')
param location string

@description('The name of the Azure Storage account to deploy. This must be globally unique.')
param storageAccountName string

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
}

output storageAccountName string = storageAccountName
