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
param topicNames array = [
  'todo1'
  'todo2'
]

var firehoseQueueName = 'firehose'
var firehoseSubscriptionName = 'firehose'
var deadLetterFirehoseQueueName = 'deadletteredfirehose'
var processSubscriptionName = 'process'

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

// Topics for each message type.
resource[] topics 'Microsoft.ServiceBus/namespaces/topics@2018-01-01-preview' = [for topicName in topicNames: {
  name: '${namespace.name}/${topicName}'
  properties: {
  }
}]

// Subscription to forward a copy of every message to the firehose queue.
resource[] topicsSubscriptionFirehose 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2018-01-01-preview' = [for topicName in topicNames: {
  name: '${namespace.name}/${topicName}/${firehoseSubscriptionName}'
  dependsOn: [
    firehoseQueue
  ]
  properties: {
    forwardTo: firehoseQueueName
  }
}]

// Subscription for the primary processing of the messages coming into the topic, with dead-lettered messages automatically forwarded to the dead-letter firehose queue.
resource[] topicsSubscriptionProcess 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2018-01-01-preview' = [for topicName in topicNames: {
  name: '${namespace.name}/${topicName}/${processSubscriptionName}'
  dependsOn: [
    deadLetterFirehoseQueue
  ]
  properties: {
    forwardDeadLetteredMessagesTo: deadLetterFirehoseQueueName
  }
}]
