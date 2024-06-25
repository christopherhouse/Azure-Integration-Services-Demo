param logAnalyticsWorkspaceName string
param location string
param retentionInDays int
param tags object = {}

resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: 'PerGB2018'
    }
  }
}

output id string = laws.id
output name string = laws.name
