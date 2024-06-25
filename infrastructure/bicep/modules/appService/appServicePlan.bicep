param appServicePlanName string
param location string
// This module expects to deploy to ASE, so only allow Isolated SKUs
@allowed(['I1v2', 'I1mv2', 'I2v2', 'I2mv2', 'I3v2', 'I3mv2', 'I4v2', 'I4mv2', 'I5v2', 'I5mv2', 'I6v2'])
param skuName string
param skuCapacity int = 1
param aseResourceId string
param zoneRedundant bool
@description('The tags to apply to the resources')
param tags object = {}

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

output id string = appServicePlan.id
