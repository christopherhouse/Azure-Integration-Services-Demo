param serviceBusNamespaceName string
param location string
param capacityUnits int = 1
param logAnalyticsWorkspaceResourceId string
param deployPrivateDns bool = false
param vnetResourceId string
param subnetResourceId string
param buildId string
param tags object = {}

var sbnsDeploymentName = '${serviceBusNamespaceName}-private-deployment-${buildId}'
var sbnsPeDeploymentName = '${serviceBusNamespaceName}-pe-${buildId}'
var dnsDeploymentName = 'privatelink-servicebus-windows-net-dns-${buildId}'

var dnsZoneName = 'privatelink.servicebus.windows.net'
var sbnsPeName = '${serviceBusNamespaceName}-pe'

module dns '../dns/privateDnsZone.bicep' = if(deployPrivateDns) {
  name: dnsDeploymentName
  params: {
    zoneName: dnsZoneName
    vnetResourceId: vnetResourceId
    tags: tags
  }

}

module sbns './serviceBusNamespace.bicep' = {
  name: sbnsDeploymentName
  params: {
    location: location
    capacityUnits: capacityUnits
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    serviceBusNamespaceName: serviceBusNamespaceName
    tags: tags
  }
}

module pe '../privateEndpoint/privateEndpoint.bicep' = {
  name: sbnsPeDeploymentName
  params: {
    dnsZoneId: dns.outputs.id
    groupId: 'namespace'
    location: location
    privateEndpointName: sbnsPeName
    subnetId: subnetResourceId
    targetResourceId: sbns.outputs.id
    tags: tags
  }
}

output id string = sbns.outputs.id
output name string = sbns.outputs.name
