@description('The region into which the resources should be deployed.')
param location string

@description('TODO')
param functionAppName string

@description('TODO')
param functionStorageAccountName string

@description('TODO')
param functionName string

@description('TODO')
param deadLetterFirehoseCosmosDBAccountName string

@description('TODO')
param deadLetterFirehoseCosmosDBDatabaseName string

@description('TODO')
param deadLetterFirehoseCosmosDBContainerName string

@description('TODO')
param appInsightsInstrumentationKey string

@description('TODO')
@secure()
param serviceBusConnectionString string

@description('TODO')
param deadLetterFirehoseQueueName string

var firehoseStorageConnectionStringAppSettingName = 'FirehoseStorage'

// Create a function app and function to listen to the firehose queue and save the messages to the firehose storage account.
module deadLetterFirehoseFunctionAppModule '../function-app.bicep' = {
  name: 'deadLetterFirehoseFunctionAppModule'
  params: {
    location: location
    appName: functionAppName
    functionStorageAccountName: functionStorageAccountName
    appInsightsInstrumentationKey: appInsightsInstrumentationKey
    serviceBusConnectionString: serviceBusConnectionString
    extraConfiguration: {
      name: firehoseStorageConnectionStringAppSettingName
      value: 'TODO'
    }
  }
}

// Get a reference to the function app that was created, so we can use it below.
resource functionApp 'Microsoft.Web/sites@2020-06-01' existing = {
  name: functionAppName
}

// Create a function.
resource function 'Microsoft.Web/sites/functions@2020-06-01' = {
  name: functionName
  parent: functionApp
  dependsOn: [
    deadLetterFirehoseFunctionAppModule
  ]
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'message'
          type: 'serviceBusTrigger'
          direction: 'in'
          queueName: deadLetterFirehoseQueueName
          connection: deadLetterFirehoseFunctionAppModule.outputs.serviceBusConnectionAppSettingName
        }
        {
          name: 'deadLetterDocument'
          type: 'cosmosDB'
          databaseName: deadLetterFirehoseCosmosDBDatabaseName
          collectionName: deadLetterFirehoseCosmosDBContainerName
          direction: 'out'
          connectionStringSetting: 'TODO'
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
            TraceWriter log,
            out object deadLetterDocument)
        {
            log.Info($"C# Service Bus trigger function processed message: {message}");

            // TODO wrap in a JSON object?
            deadLetterDocument = new {
              todo = 'todo',
              message = message
            };
        }
      '''
    }
  }
}
