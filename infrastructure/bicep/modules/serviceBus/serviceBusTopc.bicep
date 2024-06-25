param topicName string
param serviceBusNamespaceName string
param maxTopicSize int = 1024

var topicFullName = '${serviceBusNamespaceName}/${topicName}'

resource topic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = {
  name: topicFullName
  properties: {
    maxSizeInMegabytes: maxTopicSize
  }
}

output id string = topic.id
output name string = topic.name
