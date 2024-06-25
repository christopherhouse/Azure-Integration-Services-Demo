@description('The name of the NSG to create')
param nsgName string

@description('The region where the NSG will be created')
param location string

@description('The resource ID of the Log Analytics workspace where logs will be sent')
param logAnalyticsWorkspaceResourceId string

@description('The tags to associate with the NSG')
param tags object = {}

// Default NSG config which allows traffic in from vnet and traffic out to the internet
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'DenySSHRDPOutbound'
        properties: {
          priority: 3000
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Deny'
          direction: 'Outbound'
          description: 'Deny Management traffic outbound'
        }
      }        
    ]
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: nsg
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

output id string = nsg.id
output name string = nsg.name
