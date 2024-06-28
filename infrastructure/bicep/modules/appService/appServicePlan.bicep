param appServicePlanName string
param location string
// This module expects to deploy to ASE, so only allow Isolated SKUs
@allowed(['I1v2', 'I1mv2', 'I2v2', 'I2mv2', 'I3v2', 'I3mv2', 'I4v2', 'I4mv2', 'I5v2', 'I5mv2', 'I6v2'])
param skuName string
param skuCapacity int = 1
param aseResourceId string
param zoneRedundant bool
@description('The tags to apply to the resources')
param tags object
param webPlanContributorGroupObjectId string = ''

var webPlanContributorRoleId = '2cc479cb-7b4d-49a8-b449-8c00fd0f0a4b'

resource role 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: webPlanContributorRoleId
  scope: subscription()
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  properties: {
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerSizeId: 0
    hostingEnvironmentProfile: {
      id: aseResourceId
    }
    zoneRedundant: zoneRedundant
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (length(webPlanContributorGroupObjectId) > 0) {
  name: guid(appServicePlan.id, webPlanContributorGroupObjectId, webPlanContributorRoleId)
  scope: appServicePlan
  properties: {
    principalId: webPlanContributorGroupObjectId
    roleDefinitionId: role.id
    principalType: 'ServicePrincipal'
  }
}

output id string = appServicePlan.id
