@description('The name of the Key Vault to be created')
param keyVaultName string

@description('The region where the Key Vault will be created')
param location string

@description('The resource id of the log analytics workspace to send logs to')
param logAnalyticsWorkspaceResourceId string

@description('The resource ID of the vnet that the Key Vault DNS zone will be linked to')
param vnetResourceId string

@description('The resource id of the subnet to link the private endpoint to')
param servicesSubnetResourceId string

@description('Deployment identifier, used to ensure uniqueness of deployment names')
param deploymentId string

@description('The tags to apply to the Key Vault')
param tags object = {}

var kvDeploymentName = '${keyVaultName}-private-kv-${deploymentId}'

var kvDnsZoneName = 'privatelink.vaultcore.azure.net'
var kvDnsZoneDeploymentName = '${kvDnsZoneName}-${deploymentId}'

var kvPeName = '${keyVaultName}-pe'
var kvPeDeploymentName = '${kvPeName}-${deploymentId}'

module kv './keyVault.bicep' = {
  name: kvDeploymentName
  params: {
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    tags: tags
  }
}

module kvDns '../dns/privateDnsZone.bicep' = {
  name: kvDnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: kvDnsZoneName
    tags: tags
  }
}

module kvPe '../privateEndpoint/privateEndpoint.bicep' = {
  name: kvPeDeploymentName
  params: {
    location: location
    dnsZoneId: kvDns.outputs.id
    groupId: 'vault'
    privateEndpointName: kvPeName
    subnetId: servicesSubnetResourceId
    targetResourceId: kv.outputs.id
    tags: tags
  }
}

output id string = kv.outputs.id
output name string = kv.outputs.name
