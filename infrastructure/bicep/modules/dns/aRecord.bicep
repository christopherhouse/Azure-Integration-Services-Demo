param zoneName string
param recordNames array
param ipAddress string

resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: zoneName
  scope: resourceGroup()
}

resource record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = [for recordName in recordNames: {
  name: recordName
  parent: zone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}]
