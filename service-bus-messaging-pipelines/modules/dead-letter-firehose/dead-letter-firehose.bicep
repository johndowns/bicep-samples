@description('The region into which the resources should be deployed.')
param location string

@description('TODO')
param functionAppName string

@description('The name of the Azure Storage account that the Azure Functions app should use for metadata.')
param functionStorageAccountName string

@description('The instrumentation key used to identify Application Insights telemetry.')
param appInsightsInstrumentationKey string

@description('TODO')
@secure()
param serviceBusConnectionString string

@description('TODO')
param deadLetterFirehoseQueueName string

@description('The name of the Cosmos DB account to create for storing the dead-letter firehose messages. This must be globally unique.')
param deadLetterFirehoseCosmosDBAccountName string

var databaseName = 'ServerlessMessagingDemo'
var containerName = 'deadletteredmessages'
var containerPartitionKey = '/todo'
var functionName = 'ProcessDeadLetterFirehoseQueueMessage'

// Create a Cosmos DB account, database, and container for storing the dead-lettered messages.
module deadLetterFirehoseCosmosDBModule 'cosmos-db.bicep' = {
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