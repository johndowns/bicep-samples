param location string = resourceGroup().location
param namespaceName string = 'sb-${uniqueString(resourceGroup().id)}'
param skuName string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  default: 'Standard'
}

var firehoseQueueName = 'firehose'
var firehoseSubscriptionName = 'firehose'
var deadLetterFirehoseQueueName = 'deadletteredfirehose'
var processSubscriptionName = 'process'
var topic1Name = 'topic1'

resource namespace 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: skuName
  }
  properties:{
    zoneRedundant: (skuName == 'Premium')
  }
}

// Queue to receive a copy of every message on every topic.
resource firehoseQueue 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = {
  name: '${namespace.name}/${firehoseQueueName}'
  properties: {
    requiresDuplicateDetection: false
    requiresSession: false
    enablePartitioning: false
  }
}

// Queue to receive all dead-lettered messages on the 'process' subscriptions on every topic.
resource deadLetterFirehoseQueue 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = {
  name: '${namespace.name}/${deadLetterFirehoseQueueName}'
  properties: {
    requiresDuplicateDetection: false
    requiresSession: false
    enablePartitioning: false
  }
}

// TODO the below should be updated with a loop when Bicep supports this.

resource topic1 'Microsoft.ServiceBus/namespaces/topics@2018-01-01-preview' = {
  name: '${namespace.name}/${topic1Name}'
  properties: {
  }
}

resource topic1SubscriptionFirehose 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2018-01-01-preview' = {
  name: '${namespace.name}/${topic1Name}/${firehoseSubscriptionName}'
  dependsOn: [
    firehoseQueue
  ]
  properties: {
    forwardTo: firehoseQueueName
  }
}

resource topic1SubscriptionProcess 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2018-01-01-preview' = {
  name: '${namespace.name}/${topic1Name}/${processSubscriptionName}'
  dependsOn: [
    deadLetterFirehoseQueue
  ]
  properties: {
    forwardDeadLetteredMessagesTo: deadLetterFirehoseQueueName
  }
}