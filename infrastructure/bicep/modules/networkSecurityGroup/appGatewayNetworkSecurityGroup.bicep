@description('The name of the NSG to create')
param nsgName string

@description('The region where the NSG will be created')
param location string

@description('The resource ID of the Log Analytics workspace where logs will be sent')
param logAnalyticsWorkspaceResourceId string

@description('The destination IP addresses for HTTPS inbound traffic')
param appGatewayInbdoundAddresses string[]

@description('The tags to associate with the NSG')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
    {
      name: 'Alllow_HTTPS_From_Internet'
      properties: {
        protocol: 'TCP'
        sourcePortRange: '*'
        sourceAddressPrefix: 'Internet'
        access: 'Allow'
        priority: 1000
        direction: 'Inbound'
        sourcePortRanges: []
        destinationPortRange: '443'
        sourceAddressPrefixes: []
        destinationAddressPrefixes: appGatewayInbdoundAddresses
      
      }
    }
    {
      name: 'Allow_Gateway_Manager_To_Any'
      properties: {
        protocol: 'TCP'
        sourcePortRange: '*'
        sourceAddressPrefix: 'GatewayManager'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 1024
        direction: 'Inbound'
        sourcePortRanges: []
        destinationPortRanges: [
          '65200-65535'
        ]
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
      }
    }
    // {
    //   name: 'DenySSHRDPOutbound'
    //   properties: {
    //     priority: 3000
    //     protocol: 'TCP'
    //     sourcePortRange: '*'
    //     destinationPortRanges: [
    //       '22'
    //       '3389'
    //     ]
    //     sourceAddressPrefix: 'VirtualNetwork'
    //     destinationAddressPrefix: '*'
    //     access: 'Deny'
    //     direction: 'Outbound'
    //     description: 'Deny Management traffic outbound'
    //   }
    // }    
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
