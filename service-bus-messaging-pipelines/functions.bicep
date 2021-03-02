@description('The name of the Azure Functions application to create. This must be globally unique.')
param functionAppName string

@description('The name of the Service Bus connection string app setting.')
param serviceBusConnectionAppSettingName string

@description('The list of queue-triggered functions to create.')
param serviceBusQueueFunctions array

@description('The list of topic-triggered functions to create.')
param serviceBusTopicSubscriptions array

resource functionApp 'Microsoft.Web/sites@2020-06-01' existing = {
  name: functionAppName
}

// TODO combine the below - this will probably require constructing a binding dynamically, which will require variable loops

resource queueFunction 'Microsoft.Web/sites/functions@2020-06-01' = [for serviceBusQueueFunction in serviceBusQueueFunctions: {
  name: '${functionApp.name}/${serviceBusQueueFunction.functionName}'
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'message'
          type: 'serviceBusTrigger'
          direction: 'in'
          queueName: serviceBusQueueFunction.queueName
          connection: serviceBusConnectionAppSettingName
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

resource topicFunction 'Microsoft.Web/sites/functions@2020-06-01' = [for serviceBusTopicSubscription in serviceBusTopicSubscriptions: {
  name: '${functionApp.name}/${serviceBusTopicSubscription.functionName}'
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'message'
          type: 'serviceBusTrigger'
          direction: 'in'
          topicName: serviceBusTopicSubscription.topicName
          subscriptionName: serviceBusTopicSubscription.subscriptionName
          connection: serviceBusConnectionAppSettingName
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
