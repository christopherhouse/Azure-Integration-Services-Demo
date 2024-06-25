@description('The name of the private endpoint to create')
param privateEndpointName string

@description('The region where the private endpoint will be created')
param location string

@description('The ID of the subnet where the private endpoint will be created')
param subnetId string

@description('The ID of the resource to which the private endpoint will be connected')
param targetResourceId string

@description('The group ID of the service type that they private endpoint will be connect to')
param groupId string

@description('The resource ID of the private DNS zone for this resource')
param dnsZoneId string

@description('The tags to associate with the private endpoint')
param tags object = {}

var nicName = '${privateEndpointName}-nic'

resource pe 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: nicName
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: [groupId]
        }
      }
    ]
  }
}

resource peDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  name: '${privateEndpointName}-dns-group'
  parent: pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: dnsZoneId
        }
      }
    ]
  }
}
