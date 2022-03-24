@description('The location into which regionally scoped resources should be deployed.')
param location string

@description('The name of the API Management service instance to create. This must be globally unique.')
param apiManagementServiceName string

@description('The name of the API publisher. This information is used by API Management.')
param apiManagementPublisherName string

@description('The email address of the API publisher. This information is used by API Management.')
param apiManagementPublisherEmail string

@description('The name of the SKU to use when creating the API Management service instance.')
@allowed([
  'Premium'
  'Standard'
  'Basic'
  'Developer'
  'Consumption'
])
param apiManagementSkuName string

@description('The number of worker instances of your API Management service that should be provisioned.')
param apiManagementSkuCount int

@description('The custom host name to use for the API Management gateway.')
param customHostName string = ''

var apiManagementServiceHostnameConfigurations = (customHostName != '') ? [
    {
      hostName: customHostName
      certificateSource: 'Managed'
      type: 'Proxy'
    }
  ]: []

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: apiManagementSkuName
    capacity: apiManagementSkuCount
  }
  properties:{
    virtualNetworkType: 'None'
    publisherEmail: apiManagementPublisherEmail
    publisherName: apiManagementPublisherName
    hostnameConfigurations: apiManagementServiceHostnameConfigurations
  }
}

output apiManagementServiceGatewayHostName string = apiManagementService.properties.hostnameConfigurations[0].hostName
