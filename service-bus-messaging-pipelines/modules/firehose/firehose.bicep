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
param firehoseQueueName string

@description('TODO')
param firehoseStorageAccountName string

var containerName = 'firehose'
var containerImmutabilityPeriodSinceCreationInDays = 365
var functionName = 'ProcessFirehoseQueueMessage'

// Create a storage account and immutable container for storing the firehose messages.
module firehoseStorageAccountModule 'storage.bicep' = {
  name: 'firehoseStorageAccountModule'
  params: {
    location: location
    storageAccountName: firehoseStorageAccountName
    containerName: containerName
    containerImmutabilityPeriodSinceCreationInDays: containerImmutabilityPeriodSinceCreationInDays
  }
}

// Create the function app and function to listen to the firehose queue and write the messages to the storage container.
module firehoseFunctionModule 'function.bicep' = {
  name: 'firehoseFunctionModule'
  dependsOn: [
    firehoseStorageAccountModule
  ]
  params: {
    location: location
    functionAppName: functionAppName
    functionName: functionName
    functionStorageAccountName: functionStorageAccountName
    firehoseStorageAccountName: firehoseStorageAccountName
    firehoseContainerName: containerName
    appInsightsInstrumentationKey: appInsightsInstrumentationKey
    serviceBusConnectionString: serviceBusConnectionString
    firehoseQueueName: firehoseQueueName
  }
}
