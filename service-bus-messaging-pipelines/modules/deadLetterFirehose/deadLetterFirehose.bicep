@description('The region into which the resources should be deployed.')
param location string

@description('TODO')
param functionAppName string

@description('TODO')
param functionStorageAccountName string

@description('TODO')
param appInsightsInstrumentationKey string

@description('TODO')
@secure()
param serviceBusConnectionString string

@description('TODO')
param deadLetterFirehoseQueueName string

@description('TODO')
param deadLetterFirehoseCosmosDBAccountName string

var databaseName = 'ServerlessMessagingDemo'
var containerName = 'deadletteredmessages'
var containerPartitionKey = '/todo'
var functionName = 'ProcessDeadLetterFirehoseQueueMessage'

// Create a Cosmos DB account, database, and container for storing the dead-lettered messages.
module deadLetterFirehoseCosmosDBModule 'cosmosDB.bicep' = {
  name: 'deadLetterFirehoseCosmosDBModule'
  params: {
    location: location
    accountName: deadLetterFirehoseCosmosDBAccountName
    databaseName: databaseName
    containerName: containerName
    containerPartitionKey: containerPartitionKey
  }
}

module deadLetterFirehoseFunctionModule 'function.bicep' = {
  name: 'deadLetterFirehoseFunctionModule'
  dependsOn: [
    deadLetterFirehoseCosmosDBModule
  ]
  params: {
    location: location
    functionAppName: functionAppName
    functionName: functionName
    functionStorageAccountName: functionStorageAccountName
    deadLetterFirehoseCosmosDBAccountName: deadLetterFirehoseCosmosDBAccountName
    deadLetterFirehoseCosmosDBDatabaseName: databaseName
    deadLetterFirehoseCosmosDBContainerName: containerName
    appInsightsInstrumentationKey: appInsightsInstrumentationKey
    serviceBusConnectionString: serviceBusConnectionString
    deadLetterFirehoseQueueName: deadLetterFirehoseQueueName
  }
}
