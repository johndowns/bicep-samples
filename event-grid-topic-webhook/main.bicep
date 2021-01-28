param eventGridTopicName string
param eventGridSubscriptionName string
param eventGridSubscriptionUrl string
param location string = resourceGroup().location

resource eventGridTopic 'Microsoft.EventGrid/topics@2020-06-01' = {
  location: location
  name: eventGridTopicName
  properties: {}
}

resource eventGridSubscription 'Microsoft.EventGrid/topics/providers/eventSubscriptions@2020-06-01' = {
  location: location
  scope: eventGridTopic
  name: '${eventGridTopicName}/Microsoft.EventGrid/${eventGridSubscriptionName}'
  properties: {
    destination: {
      endpointType: 'Webhook'
      properties: {
        endpointUrl: eventGridSubscriptionUrl
      }
    }
    filter: {
      includedEventTypes: [
        'All'
      ]
    }
  }
}
