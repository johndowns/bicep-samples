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

@description('The name of the Azure Functions application to create. This must be globally unique.')
param functionAppName string = 'fn-${uniqueString(resourceGroup().id)}'

@description('The name of the SKU to use when creating the Azure Functions plan. Common SKUs include Y1 (consumption) and EP1, EP2, and EP3 (premium).')
param functionPlanSkuName string = 'Y1'

module serviceBus 'service-bus.bicep' = {
  name: 'serviceBus'
  params: {
    location: location
    namespaceName: serviceBusNamespaceName
    skuName: serviceBusSkuName
    topicNames: serviceBusTopicNames
  }
}

module functionApp 'function-app.bicep' = {
  name: 'functionApp'
  params: {
    location: location
    functionPlanSkuName: functionPlanSkuName
    appName: functionAppName
    serviceBusConnectionString: serviceBus.outputs.serviceBusReaderConnectionString
  }
}

module functions 'functions.bicep' = {
  name: 'functions'
  params: {
    functionAppName: functionAppName
    serviceBusConnectionAppSettingName: functionApp.outputs.serviceBusConnectionAppSettingName
    serviceBusQueueFunctions: [
      {
        queueName: serviceBus.outputs.deadLetterFirehoseQueueName
        functionName: 'ProcessDeadLetterFirehoseQueueMessage'
      }
      {
        queueName: serviceBus.outputs.firehoseQueueName
        functionName: 'ProcessFirehoseQueueMessage'
      }
    ]
    serviceBusTopicSubscriptions: [ // TODO move to variable loop based on parameter
      {
        topicName: 'todo1'
        subscriptionName: serviceBus.outputs.processSubscriptionName
      }
      {
        topicName: 'todo2'
        subscriptionName: serviceBus.outputs.processSubscriptionName
      }
    ]
  }
}
