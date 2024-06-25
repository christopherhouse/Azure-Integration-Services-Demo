param buildId string
param vnetResourceId string
param tags object

var blobDnsZone = 'privatelink.blob.${environment().suffixes.storage}'
var fileDnsZone = 'privatelink.file.${environment().suffixes.storage}'
var queueDnsZone = 'privatelink.queue.${environment().suffixes.storage}'
var tableDnsZone = 'privatelink.table.${environment().suffixes.storage}'

var blobDnsZoneDeploymentName = '${blobDnsZone}-${buildId}'
var fileDnsZoneDeploymentName = '${fileDnsZone}-${buildId}'
var queueDnsZoneDeploymentName = '${queueDnsZone}-${buildId}'
var tableDnsZoneDeploymentName = '${tableDnsZone}-${buildId}'

module blobDns '../dns/privateDnsZone.bicep' = {
  name: blobDnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: blobDnsZone
    tags: tags
  }
}

module fileDns '../dns/privateDnsZone.bicep' = {
  name: fileDnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: fileDnsZone
    tags: tags
  }
}

module queueDns '../dns/privateDnsZone.bicep' = {
  name: queueDnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: queueDnsZone
    tags: tags
  }
}

module tableDns '../dns/privateDnsZone.bicep' = {
  name: tableDnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: tableDnsZone
    tags: tags
  }
}

output blobDnsZoneId string = blobDns.outputs.id
output fileDnsZoneId string = fileDns.outputs.id
output queueDnsZoneId string = queueDns.outputs.id
output tableDnsZoneId string = tableDns.outputs.id
