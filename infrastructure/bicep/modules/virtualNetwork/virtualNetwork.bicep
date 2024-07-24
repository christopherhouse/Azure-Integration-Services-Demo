import * as udt from '../userDefined/userDefinedTypes.bicep'

param virtualNetworkName string
param location string
param virtualNetworkAddressSpaces string[]
param apimNsgResourceId string
param appGatewayNsgResourceId string
param defaultNsgResourceId string
param subnetConfiguration udt.subnetConfigurationsType
param tags object = {}


var aseDelegation = 'Microsoft.Web/hostingEnvironments'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  tags: tags
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetworkAddressSpaces
    }
    subnets: [
      {
        name: subnetConfiguration.bastionSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.bastionSubnet.addressPrefix
        }
      }
      {
        name: subnetConfiguration.apimSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.apimSubnet.addressPrefix
          networkSecurityGroup: {
            id: apimNsgResourceId
          }
        }
      }
      {
        name: subnetConfiguration.appGwSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.appGwSubnet.addressPrefix
          networkSecurityGroup: {
            id: appGatewayNsgResourceId
          }
        }
      }
      {
        name: subnetConfiguration.servicesSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.servicesSubnet.addressPrefix
          networkSecurityGroup: {
            id: defaultNsgResourceId
          }
        }
      }
      {
        name: subnetConfiguration.aseSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.aseSubnet.addressPrefix
          delegations: [
            {
              name: aseDelegation
              properties: {
                serviceName: aseDelegation
              }
            }
          ]
          networkSecurityGroup: {
            id: apimNsgResourceId
          }
        }
      }
      {
        name: subnetConfiguration.runnersSubnet.name
        properties: {
          addressPrefix: subnetConfiguration.runnersSubnet.addressPrefix
          networkSecurityGroup: {
            id: defaultNsgResourceId
          }
        }
      }
    ]
  }
}

output id string = vnet.id
output name string = vnet.name
output apimSubnetResourceId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetConfiguration.apimSubnet.name)
output appGwSubnetResourceId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetConfiguration.appGwSubnet.name)
output servicesSubnetResourceId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetConfiguration.servicesSubnet.name)
output aseSubnetResourceId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetConfiguration.aseSubnet.name)
output runnersSubnetResourceId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetConfiguration.runnersSubnet.name)
