@description('The region into which the Azure Storage resources should be deployed.')
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

@minValue(1)
@description('TODO')
param firehoseStorageAccountContainerImmutabilityPeriodSinceCreationInDays int

var containerName = 'firehose'
var functionName = 'ProcessFirehoseQueueMessage'

// Create a storage account and container for storing the firehose messages.

resource firehoseStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: firehoseStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }

  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = if (containerName != '') {
  name: containerName
  parent: firehoseStorageAccount::blobService
  properties: {
    publicAccess: 'None'
  }

  resource immutabilityPolicy 'immutabilityPolicies' = {
    name: 'default'
    properties: {
      immutabilityPeriodSinceCreationInDays: firehoseStorageAccountContainerImmutabilityPeriodSinceCreationInDays
      allowProtectedAppendWrites: false
    }
  }
}

// Create a function app.
module firehoseFunctionAppModule 'function-app.bicep' = {
  name: 'firehoseFunctionAppModule'
  params: {
    location: location
    appName: functionAppName
    functionStorageAccountName: functionStorageAccountName
    appInsightsInstrumentationKey: appInsightsInstrumentationKey
    serviceBusConnectionString: serviceBusConnectionString
    extraConfiguration: {
      name: 'FirehoseStorage'
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
          path: '${containerName}/{DateTime}'
          connection: 'AzureWebJobsStorage' // TODO
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
