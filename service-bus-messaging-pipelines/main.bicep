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

@description('The name of the Azure Functions application to create for send messages. This must be globally unique.')
param sendFunctionAppName string = 'fn-send-${uniqueString(resourceGroup().id)}'

@description('TODO')
param sendFunctionPlanName string = 'Send-Plan'

@description('TODO')
param sendFunctionStorageAccountName string = 'fnstorsend${uniqueString(resourceGroup().id)}'

@description('TODO')
param sendFunctionApplicationInsightsName string = 'Send-ApplicationInsights'

@description('The name of the Azure Functions application to create for listening to messages. This must be globally unique.')
param listenFunctionAppName string = 'fn-listen-${uniqueString(resourceGroup().id)}'

@description('TODO')
param listenFunctionPlanName string = 'Listen-Plan'

@description('TODO')
param listenFunctionStorageAccountName string = 'fnstorlist${uniqueString(resourceGroup().id)}'

@description('TODO')
param listenFunctionApplicationInsightsName string = 'Listen-ApplicationInsights'

@description('The name of the SKU to use when creating the Azure Functions plan. Common SKUs include Y1 (consumption) and EP1, EP2, and EP3 (premium).')
param functionPlanSkuName string = 'Y1'

module serviceBus 'modules/service-bus.bicep' = {
  name: 'serviceBus'
  params: {
    location: location
    namespaceName: serviceBusNamespaceName
    skuName: serviceBusSkuName
    topicNames: serviceBusTopicNames
  }
}

module sendFunctionApp 'modules/function-app.bicep' = {
  name: 'sendFunctionApp'
  params: {
    location: location
    functionPlanSkuName: functionPlanSkuName
    functionPlanName: sendFunctionPlanName
    appInsightsName: sendFunctionApplicationInsightsName
    storageAccountName: sendFunctionStorageAccountName
    appName: sendFunctionAppName
    serviceBusConnectionString: serviceBus.outputs.serviceBusSendConnectionString
  }
}

module listenFunctionApp 'modules/function-app.bicep' = {
  name: 'listenFunctionApp'
  params: {
    location: location
    functionPlanSkuName: functionPlanSkuName
    functionPlanName: listenFunctionPlanName
    appInsightsName: listenFunctionApplicationInsightsName
    storageAccountName: listenFunctionStorageAccountName
    appName: listenFunctionAppName
    serviceBusConnectionString: serviceBus.outputs.serviceBusListenConnectionString
  }
}

module listenFunctions 'modules/listen-functions.bicep' = {
  name: 'listenFunctions'
  params: {
    functionAppName: listenFunctionAppName
    serviceBusConnectionAppSettingName: listenFunctionApp.outputs.serviceBusConnectionAppSettingName
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
        functionName: 'ProcessTodo1TopicMessage'
      }
      {
        topicName: 'todo2'
        subscriptionName: serviceBus.outputs.processSubscriptionName
        functionName: 'ProcessTodo2TopicMessage'
      }
    ]
  }
}

// TODO add send function

module sendFunction 'modules/send-function.bicep' = {
  name: 'sendFunction'
  params: {
    functionAppName: sendFunctionAppName
    serviceBusConnectionAppSettingName: listenFunctionApp.outputs.serviceBusConnectionAppSettingName
    serviceBusTopicFunctions: [ // TODO move to variable loop based on parameter
      {
        topicName: 'todo1'
        functionName: 'SendTodo1TopicMessage'
      }
      {
        topicName: 'todo2'
        functionName: 'SendTodo2TopicMessage'
      }
    ]
  }
}