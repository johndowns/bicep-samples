@description('The region into which the Service Bus resources should be deployed.')
param location string

@description('The name of the Service Bus namespace to deploy. This must be globally unique.')
param namespaceName string

@description('The SKU of Service Bus to deploy.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string

@description('An array specifying the names of topics that should be deployed.')
param topicNames array

var processorAuthorizationRuleName = 'ProcessorFunction'
var firehoseAuthorizationRuleName = 'FirehoseFunction'
var senderAuthorizationRuleName = 'SenderFunction'
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

resource processorAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = {
  name: processorAuthorizationRuleName
  parent: namespace
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource firehoseAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = {
  name: firehoseAuthorizationRuleName
  parent: namespace
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource senderAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = {
  name: senderAuthorizationRuleName
  parent: namespace
  properties: {
    rights: [
      'Send'
    ]
  }
}

// Queue to receive a copy of every message on every topic.
resource firehoseQueue 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = {
  name: firehoseQueueName
  parent: namespace
  properties: {
    requiresDuplicateDetection: false
    requiresSession: false
    enablePartitioning: false
  }
}

// Queue to receive all dead-lettered messages on the 'process' subscriptions on every topic.
resource deadLetterFirehoseQueue 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = {
  name: deadLetterFirehoseQueueName
  parent: namespace
  properties: {
    requiresDuplicateDetection: false
    requiresSession: false
    enablePartitioning: false
  }
}

// Topics for each message type.
resource topics 'Microsoft.ServiceBus/namespaces/topics@2018-01-01-preview' = [for topicName in topicNames: {
  name: topicName
  parent: namespace
}]

// Subscription to forward a copy of every message to the firehose queue.
resource topicsSubscriptionFirehose 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2018-01-01-preview' = [for topicName in topicNames: {
  name: '${namespace.name}/${topicName}/${firehoseSubscriptionName}'
  dependsOn: [
    firehoseQueue // This requires an explicitly dependency because the firehoseQueue.name property is a multipart name, which isn't accepted by the forwardTo property.
    topics
  ]
  properties: {
    forwardTo: firehoseQueueName
  }
}]

// Subscription for the primary processing of the messages coming into the topic, with dead-lettered messages automatically forwarded to the dead-letter firehose queue.
resource topicsSubscriptionProcess 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2018-01-01-preview' = [for topicName in topicNames: {
  name: '${namespace.name}/${topicName}/${processSubscriptionName}'
  dependsOn: [
    deadLetterFirehoseQueue // This requires an explicitly dependency because the deadLetterFirehoseQueue.name property is a multipart name, which isn't accepted by the forwardDeadLetteredMessagesTo property.
    topics
  ]
  properties: {
    forwardDeadLetteredMessagesTo: deadLetterFirehoseQueueName
  }
}]

output processorConnectionString string = listKeys(processorAuthorizationRule.id, processorAuthorizationRule.apiVersion).primaryConnectionString
output firehoseConnectionString string = listKeys(firehoseAuthorizationRule.id, firehoseAuthorizationRule.apiVersion).primaryConnectionString
output senderConnectionString string = listKeys(senderAuthorizationRule.id, senderAuthorizationRule.apiVersion).primaryConnectionString
output firehoseQueueName string = firehoseQueueName
output deadLetterFirehoseQueueName string = deadLetterFirehoseQueueName
output processSubscriptionName string = processSubscriptionName
