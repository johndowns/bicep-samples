@description('The region into which the resources should be deployed.')
param location string

@description('The name of the Cosmos DB account to create. This must be globally unique.')
param accountName string

@description('TODO')
param databaseName string

@description('TODO')
param containerName string

@description('TODO')
param containerPartitionKey string

resource account 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: accountName
  location: location
  properties: {
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session' // TODO parameterize
    }
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-04-01' = {
  name: databaseName
  parent: account
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 400 // TODO parameterize, maybe make serverless
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-03-01-preview' = {
  name: containerName
  parent: database
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        kind: 'Hash'
        paths: [
          containerPartitionKey
        ]
      }
    }
  }
}
