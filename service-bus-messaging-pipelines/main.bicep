@description('The region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the Service Bus namespace to deploy. This must be globally unique.')
param serviceBusNamespaceName string = 'sb-${uniqueString(resourceGroup().id)}'

@description('The SKU of Service Bus to deploy.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param serviceBusSkuName string = 'Standard'

@description('An array specifying the names of topics that should be deployed.')
param serviceBusTopicNames array = [
  'todo1'
  'todo2'
]

@description('TODO')
param functionAppStorageAccountName string = 'fn${uniqueString(resourceGroup().id)}'

@description('The name of the Azure Functions application to create for listening to messages. This must be globally unique.')
param processorFunctionAppName string = 'fn-processor-${uniqueString(resourceGroup().id, 'processor')}'

@description('TODO')
param firehoseFunctionAppName string = 'fn-firehose-${uniqueString(resourceGroup().id, 'firehose')}'

@description('TODO')
param senderFunctionAppName string = 'fn-sender-${uniqueString(resourceGroup().id, 'sender')}'

@description('TODO')
param firehoseStorageAccountName string = 'firehose${uniqueString(resourceGroup().id, 'firehose')}'

var appInsightsName = 'ServerlessMessagingDemo'

module serviceBusModule 'modules/service-bus.bicep' = {
  name: 'serviceBusModule'
  params: {
    location: location
    namespaceName: serviceBusNamespaceName
    skuName: serviceBusSkuName
    topicNames: serviceBusTopicNames
  }
}

// Deploy the shared Application Insights instance.

module appInsightsModule 'modules/application-insights.bicep' = {
  name: 'appInsightsModule'
  params: {
    location: location
    appInsightsName: appInsightsName
  }
}

// Deploy the shared Azure Storage account for all function apps to use for their metadata.

module functionAppStorageAccountModule 'modules/storage.bicep' = {
  name: 'functionAppStorageAccountModule'
  params: {
    location: location
    storageAccountName: functionAppStorageAccountName
  }
}

// Deploy the resources for processing the primary queue messages.
module processorsModule 'modules/processors.bicep' = {
  name: 'processorsModule'
  params: {
    location: location
    functionAppName: processorFunctionAppName
    functionStorageAccountName: functionAppStorageAccountModule.outputs.storageAccountName
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    serviceBusConnectionString: serviceBusModule.outputs.processorConnectionString
    serviceBusTopicNames: serviceBusTopicNames
    processSubscriptionName: serviceBusModule.outputs.processSubscriptionName
  }
}

// Deploy the resources for processing the firehose queue messages.
module firehoseModule 'modules/firehose.bicep' = {
  name: 'firehoseModule'
  params: {
    location: location
    functionAppName: firehoseFunctionAppName
    functionStorageAccountName: functionAppStorageAccountModule.outputs.storageAccountName
    firehoseStorageAccountName: firehoseStorageAccountName
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    serviceBusConnectionString: serviceBusModule.outputs.firehoseConnectionString
    firehoseQueueName: serviceBusModule.outputs.firehoseQueueName
  }
}

// Deploy the resources for processing the primary queue messages.
module sendersModule 'modules/senders.bicep' = {
  name: 'sendersModule'
  params: {
    location: location
    functionAppName: senderFunctionAppName
    functionStorageAccountName: functionAppStorageAccountModule.outputs.storageAccountName
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    serviceBusConnectionString: serviceBusModule.outputs.senderConnectionString
    serviceBusTopicNames: serviceBusTopicNames
  }
}
