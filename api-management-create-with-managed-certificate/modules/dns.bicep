@description('The name of the DNS zone to create.')
param dnsZoneName string

@description('The name of the CNAME record to create within the DNS zone. The record will be an alias to your API Management gateway.')
param cnameRecordName string

@description('The gateway hostname of the API Management service instance.')
param apiManagementGatewayHostName string

@description('The unique domain identifier for the API Management gateway.')
param domainOwnershipIdentifier string

var dnsRecordTimeToLive = 3600

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZoneName
  location: 'global'
}

resource cnameRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: dnsZone
  name: cnameRecordName
  properties: {
    TTL: dnsRecordTimeToLive
    CNAMERecord: {
      cname: apiManagementGatewayHostName
    }
  }
}

resource validationTxtRecord 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  parent: dnsZone
  name: 'apimuid.${cnameRecordName}'
  properties: {
    TTL: dnsRecordTimeToLive
    TXTRecords: [
      {
        value: [
          domainOwnershipIdentifier
        ]
      }
    ]
  }
}
