param queueName string
param serviceBusNamespaceName string
param maxSizeInMegabytes int = 1024
param maxMessageSizeInKilobytes int = 1024
param maxDeliveryCount int = 10

var fullQueueName = '${serviceBusNamespaceName}/${queueName}'

resource q 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: fullQueueName
  properties: {
    deadLetteringOnMessageExpiration: true
    maxSizeInMegabytes: maxSizeInMegabytes
    maxMessageSizeInKilobytes: maxMessageSizeInKilobytes
    maxDeliveryCount: maxDeliveryCount
  }
}
