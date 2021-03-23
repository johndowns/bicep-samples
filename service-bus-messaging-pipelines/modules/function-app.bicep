@description('The location into which the Azure Functions resources should be deployed.')
param location string

@description('The name of the Azure Functions application to create. This must be globally unique.')
param appName string

@description('The Service Bus connection string to use when receiving messages.')
@secure()
param serviceBusConnectionString string

@description('TODO')
param functionStorageAccountName string

@description('TODO')
param appInsightsInstrumentationKey string

@description('TODO')
param extraConfiguration object = {}

var serviceBusConnectionAppSettingName = 'ServiceBusConnection'
var functionRuntime = 'dotnet'
var extraConfigurationArray = extraConfiguration == {} ? [] : array(extraConfiguration)

resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' existing = {
  name: functionStorageAccountName
}

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: appName
  location: location
  kind: 'functionapp'
  properties: {
    siteConfig: {
      appSettings: union(extraConfigurationArray, [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorageAccount.id, functionStorageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorageAccount.id, functionStorageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsInstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'AzureWebJobsDisableHomepage' // This hides the default Azure Functions homepage, which means that Front Door health probe traffic is significantly reduced.
          value: 'true'
        }
        {
          name: serviceBusConnectionAppSettingName
          value: serviceBusConnectionString
        }
      ])
    }
    httpsOnly: true
  }
}

output serviceBusConnectionAppSettingName string = serviceBusConnectionAppSettingName
