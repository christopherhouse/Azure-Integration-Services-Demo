param appInsightsName string
param location string
param logAnalyticsWorkspaceId string
param keyVaultName string
param buildId string
param tags object = {}

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

module connectionString '../keyVault/keyVaultSecret.bicep' = {
  name: 'app-insights-connection-string-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: 'appInsightsConnectionString'
    secretValue: ai.properties.ConnectionString
    tags: tags
  }
}

module iKey '../keyVault/keyVaultSecret.bicep' = {
  name: 'app-insights-instrumentationkey-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: 'appInsightsInstrumentationKey'
    secretValue: ai.properties.InstrumentationKey
    tags: tags
  }
}

output id string = ai.id
output name string = ai.name
output instrumentationKeySecretUri string = iKey.outputs.secretUri
output connectionStringSecretUri string = connectionString.outputs.secretUri
