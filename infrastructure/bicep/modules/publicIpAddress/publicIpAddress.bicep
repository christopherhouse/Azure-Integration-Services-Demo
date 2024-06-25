@description('The name of the Public IP Address resource to be created')
param publicIpAddressName string

@description('The DNS label for the Public IP Address.  Defaults to resource name')
param dnsLabel string = publicIpAddressName

@description('The region where the Public IP Address will be created')
param location string

@description('The tags to associate with the Public IP Address')
param tags object = {}

resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpAddressName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    dnsSettings: {
      domainNameLabel: dnsLabel
    }
    publicIPAllocationMethod: 'Static'
  }
  zones: ['1', '2', '3']
}

output id string = pip.id
output ip string = pip.properties.ipAddress
