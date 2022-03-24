@description('The location into which regionally scoped resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the API Management service instance to create. This must be globally unique.')
param apiManagementServiceName string = 'apim-${uniqueString(resourceGroup().id)}'

@description('The name of the API publisher. This information is used by API Management.')
param apiManagementPublisherName string = 'Contoso'

@description('The email address of the API publisher. This information is used by API Management.')
param apiManagementPublisherEmail string = 'test@contoso.com'

@description('The name of the SKU to use when creating the API Management service instance.')
@allowed([
  'Premium'
  'Standard'
  'Basic'
  'Developer'
  'Consumption'
])
param apiManagementSkuName string = 'Consumption'

@description('The number of worker instances of your API Management service that should be provisioned.')
param apiManagementSkuCount int = 0

@description('The name of the DNS zone to create.')
param dnsZoneName string

@description('The name of the CNAME record to create within the DNS zone. The record will be an alias to your API Management gateway.')
param cnameRecordName string = 'api'

module apiManagementDeployment1 'modules/api-management.bicep' = {
  name: 'api-management-1'
  params: {
    apiManagementPublisherEmail: apiManagementPublisherEmail
    apiManagementPublisherName: apiManagementPublisherName
    apiManagementServiceName: apiManagementServiceName
    apiManagementSkuCount: apiManagementSkuCount
    apiManagementSkuName: apiManagementSkuName
    location: location
  }
}

module apiManagementGetDomainOwnershipIdentifier 'modules/api-management-get-domain-ownership-identifier.bicep' = {
  name: 'api-management-get-domain-ownership-identifier'
  dependsOn: [
    apiManagementDeployment1
  ]
  params: {
    apiManagementServiceName: apiManagementServiceName
    location: location
  }
}

module dns 'modules/dns.bicep' = {
  name: 'dns'
  params: {
    dnsZoneName: dnsZoneName
    cnameRecordName: cnameRecordName
    domainOwnershipIdentifier: apiManagementGetDomainOwnershipIdentifier.outputs.domainOwnershipIdentifier
    apiManagementGatewayHostName: apiManagementDeployment1.outputs.apiManagementServiceGatewayHostName
  }
}

module apiManagementDeployment2 'modules/api-management.bicep' = {
  name: 'api-management-2'
  dependsOn: [
    apiManagementDeployment1
    apiManagementGetDomainOwnershipIdentifier
    dns
  ]
  params: {
    apiManagementPublisherEmail: apiManagementPublisherEmail
    apiManagementPublisherName: apiManagementPublisherName
    apiManagementServiceName: apiManagementServiceName
    apiManagementSkuCount: apiManagementSkuCount
    apiManagementSkuName: apiManagementSkuName
    customHostName: '${cnameRecordName}.${dnsZoneName}'
    location: location
  }
}
