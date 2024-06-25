import * as udt from '../userDefined/userDefinedTypes.bicep'
import * as udf from '../userDefined/userDefinedFunctions.bicep'

param functionAppName string
param location string
param aseResourceId string
param appServicePlanResourceId string
param keyVaultName string
param appInsightsConnectionStringSecretUri string
param blobDnsZoneId string
param fileDnsZoneId string
param queueDnsZoneId string
param tableDnsZoneId string
param storageSubnetId string
param enableZoneRedundancy bool
param functionsWorkerRuntime udt.functionWorkerRuntimes
param logAnalyticsWorkspaceResourceId string
param buildId string
param tags object

// User Assigned Managed Identity
var uamiName = '${functionAppName}-uami'

// Storage
var storageAccountBaseName = toLower(replace(functionAppName, '-', ''))
var storageAccountName = length(storageAccountBaseName) > 24 ? '${substring(storageAccountBaseName, 0, 22)}sa' : '${storageAccountBaseName}sa'
var storageAccountDeploymentName = '${storageAccountName}-${buildId}'
var storageAccountConnectionStringSecretName = '${storageAccountName}-connection-string'

var contentShareName = '${functionAppName}-content-share'
var fileShares = [
  {
    shareName: contentShareName
    quota: 1024
  }
]

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: uamiName
  location: location
  tags: tags
}

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kvSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: keyVaultSecretsUserRoleId
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01'= {
  name: guid(kv.id, uami.id, kvSecretsUserRole.id)
  scope: kv
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: kvSecretsUserRole.id
    principalType: 'ServicePrincipal'
  }
}

module sa '../storage/privateStorageAccount.bicep' = {
  name: storageAccountDeploymentName
  params: {
    location: location
    blobDnsZoneId: blobDnsZoneId
    buildId: buildId
    fileDnsZoneId: fileDnsZoneId
    keyVaultName: keyVaultName
    queueDnsZoneId: queueDnsZoneId
    storageAccountName: storageAccountName
    storageConnectionStringSecretName: storageAccountConnectionStringSecretName
    subnetId: storageSubnetId
    tableDnsZoneId: tableDnsZoneId
    zoneRedundant: enableZoneRedundancy
    fileShares: fileShares
    tags: tags
  }
}

// Create a .Net 6 Azure Function App using the App Service Plan and ASE resources defined in the parameters of this module
resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    keyVaultReferenceIdentity: uami.id
    serverFarmId: appServicePlanResourceId
    hostingEnvironmentProfile: {
      id: aseResourceId
    }
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: udf.formatAppServiceKeyVaultReference(sa.outputs.connectionStringSecretUri)
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: udf.formatAppServiceKeyVaultReference(appInsightsConnectionStringSecretUri)
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: udf.formatAppServiceKeyVaultReference(sa.outputs.connectionStringSecretUri)
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: contentShareName
        }
        {
          name: 'WEBSITE_SKIP_CONTENTSHARE_VALIDATION'  // AppSvc can't validate the content share when the connection string is in kv, so disable the validation :(
          value: '1'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionsWorkerRuntime
        }
      ]
      minTlsVersion: '1.2'
      http20Enabled: true
      ftpsState: 'Disabled'
      alwaysOn: true
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  dependsOn: [
    ra // Make sure the role assignment happens before we create the function app
  ]
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: functionApp
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuthenticationLogs'
        enabled: true
      }
    ]
  }
}
