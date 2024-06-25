param subscriptionName string
param serviceBusNamespaceName string
param topicName string
param sqlFilterExpression string = ''
param forwardToTopicName string = ''

var fullSubscriptionName = '${serviceBusNamespaceName}/${topicName}/${subscriptionName}'

resource subscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  name:fullSubscriptionName
  properties: {
    deadLetteringOnFilterEvaluationExceptions: true
    deadLetteringOnMessageExpiration: true
    defaultMessageTimeToLive: 'P7D'
    forwardTo: length(forwardToTopicName) > 0 ? forwardToTopicName : null
  }
}

resource rule 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = if(length(sqlFilterExpression) > 0) {
  name: 'default'
  parent: subscription
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: sqlFilterExpression
    }
  }
}

output id string = subscription.id
output name string = subscription.name
