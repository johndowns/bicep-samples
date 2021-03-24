@description('TODO')
param location string

@description('The name of the Azure Functions application in which to create the functions. This must be globally unique.')
param functionAppName string

@description('The name of the Azure Storage account that the Azure Functions app should use for metadata.')
param functionStorageAccountName string

@description('The instrumentation key used to identify Application Insights telemetry.')
param applicationInsightsInstrumentationKey string

@description('TODO')
@secure()
param serviceBusConnectionString string

@description('The list of topic names to create functions for.')
param serviceBusTopicNames array

@description('TODO')
param processSubscriptionName string

// Create a function app.
module processorFunctionAppModule '../function-app.bicep' = {
  name: 'processorFunctionAppModule'
  params: {
    location: location
    appName: functionAppName
    functionStorageAccountName: functionStorageAccountName
    applicationInsightsInstrumentationKey: applicationInsightsInstrumentationKey
    serviceBusConnectionString: serviceBusConnectionString
  }
}

resource functionApp 'Microsoft.Web/sites@2020-06-01' existing = {
  name: functionAppName
}

// Create a function for each topic subscription.
resource topicFunction 'Microsoft.Web/sites/functions@2020-06-01' = [for serviceBusTopicName in serviceBusTopicNames: {
  name: 'Process-${serviceBusTopicName}'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'message'
          type: 'serviceBusTrigger'
          direction: 'in'
          topicName: serviceBusTopicName
          subscriptionName: processSubscriptionName
          connection: processorFunctionAppModule.outputs.serviceBusConnectionAppSettingName
        }
      ]
    }
    files: {
      'run.csx': '''
        using System;

        public static void Run(
            string message,
            Int32 deliveryCount,
            DateTime enqueuedTimeUtc,
            string messageId,
            TraceWriter log)
        {
            log.Info($"C# Service Bus trigger function processed message: {message}");
        
            log.Info($"EnqueuedTimeUtc={enqueuedTimeUtc}");
            log.Info($"DeliveryCount={deliveryCount}");
            log.Info($"MessageId={messageId}");
        }
      '''
    }
  }
}]
