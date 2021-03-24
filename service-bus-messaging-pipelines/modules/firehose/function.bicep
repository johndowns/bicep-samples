@description('The region into which the resources should be deployed.')
param location string

@description('TODO')
param functionAppName string

@description('The name of the Azure Storage account that the Azure Functions app should use for metadata.')
param functionStorageAccountName string

@description('TODO')
param functionName string

@description('TODO')
param firehoseStorageAccountName string

@description('TODO')
param firehoseContainerName string

@description('TODO')
param appInsightsInstrumentationKey string

@description('TODO')
@secure()
param serviceBusConnectionString string

@description('TODO')
param firehoseQueueName string

var firehoseStorageConnectionStringAppSettingName = 'FirehoseStorage'

// Get a reference to the firehose storage account.
resource firehoseStorageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' existing = {
  name: firehoseStorageAccountName
}

// Create a function app and function to listen to the firehose queue and save the messages to the firehose storage account.
module firehoseFunctionAppModule '../function-app.bicep' = {
  name: 'firehoseFunctionAppModule'
  params: {
    location: location
    appName: functionAppName
    functionStorageAccountName: functionStorageAccountName
    appInsightsInstrumentationKey: appInsightsInstrumentationKey
    serviceBusConnectionString: serviceBusConnectionString
    extraConfiguration: {
      name: firehoseStorageConnectionStringAppSettingName
      value: 'DefaultEndpointsProtocol=https;AccountName=${firehoseStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(firehoseStorageAccount.id, firehoseStorageAccount.apiVersion).keys[0].value}'
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
    firehoseFunctionAppModule
  ]
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'message'
          type: 'serviceBusTrigger'
          direction: 'in'
          queueName: firehoseQueueName
          connection: firehoseFunctionAppModule.outputs.serviceBusConnectionAppSettingName
        }
        {
          name: 'blobOutput'
          type: 'blob'
          direction: 'out'
          path: '${firehoseContainerName}/{DateTime}' // TODO can we put into a folder structure of Y/M/D/H and then include message ID with timestamp?
          connection: firehoseStorageConnectionStringAppSettingName
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
            out string blobOutput)
        {
            log.Info($"C# Service Bus trigger function processed message: {message}");

            // TODO wrap in a JSON object?
            blobOutput = message;
        }
      '''
    }
  }
}
