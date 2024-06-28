import * as vn from './modules/virtualNetwork/virtualNetwork.bicep'

param workloadName string
param environmentSuffix string
param location string
param addressPrefixes array
param subnetConfigurations vn.subnetConfigurationsType
param logAnalyticsRetentionDays int
param deploymentId string = substring(newGuid(), 0, 8)
param tags object = {}
param appGatewayPrivateIpAddress string

// LAWS
var logAnalyticsWorkspaceName = '${workloadName}-${environmentSuffix}-laws'
var logAnalyticsWorkspaceDeploymentName = '${logAnalyticsWorkspaceName}-${deploymentId}'

// NSGs
var defaultNsgName = '${workloadName}-${environmentSuffix}-nsg'
var defaultNsgDeploymentName = '${defaultNsgName}-${deploymentId}'

var apimNsgName = '${workloadName}-${environmentSuffix}-apim-nsg'
var apimNsgDeploymentName = '${apimNsgName}-${deploymentId}'

var appGwNsgName = '${workloadName}-${environmentSuffix}-appgw-nsg'
var appGwNsgDeploymentName = '${appGwNsgName}-${deploymentId}'

// Vnet
var virtualNetworkName = '${workloadName}-${environmentSuffix}-vnet'
var virtualNetworkDeploymentName = '${virtualNetworkName}-${deploymentId}'

// Key Vault
var keyVaultName = '${workloadName}-${environmentSuffix}-kv'
var keyVaultDeploymentName = '${keyVaultName}-${deploymentId}'

// App Gateway Public IP
var appGatewayPublicIpName = '${workloadName}-${environmentSuffix}-appgw-pip'
var appGatewayPublicIpDeploymentName = '${appGatewayPublicIpName}-${deploymentId}'

// Log Analytics Workspace
module laws './modules/observability/logAnalyticsWorkspace.bicep' = {
  name: logAnalyticsWorkspaceDeploymentName
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    retentionInDays: logAnalyticsRetentionDays
    tags: tags
  }
}

// Default NSG
module nsg './modules/networkSecurityGroup/allowVnetNetworkSecurityGroup.bicep' = {
  name: defaultNsgDeploymentName
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: laws.outputs.id
    nsgName: defaultNsgName
    tags: tags
  }
}

module appGwNsg './modules/networkSecurityGroup/appGatewayNetworkSecurityGroup.bicep' = {
  name: appGwNsgDeploymentName
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: laws.outputs.id
    nsgName: appGwNsgName
    tags: tags
    appGatewayInbdoundAddresses: [
      appGwPip.outputs.ip
      appGatewayPrivateIpAddress
    ]
  }
}

// NSG required by APIM
module apimNsg './modules/networkSecurityGroup/apimNetworkSecurityGroup.bicep' = {
  name: apimNsgDeploymentName
  params: {
    location: location
    nsgName: apimNsgName
    logAnalyticsWorkspaceResourceId: laws.outputs.id
    tags: tags
  }
}

module vnet './modules/virtualNetwork/virtualNetwork.bicep' = {
  name: virtualNetworkDeploymentName
  params: {
    location: location
    apimNsgResourceId: apimNsg.outputs.id
    appGatewayNsgResourceId: appGwNsg.outputs.id
    defaultNsgResourceId: nsg.outputs.id
    virtualNetworkAddressSpaces: addressPrefixes
    virtualNetworkName: virtualNetworkName
    subnetConfiguration: subnetConfigurations
    tags: tags
  }
}

module kv './modules/keyVault/privateKeyVault.bicep' = {
  name: keyVaultDeploymentName
  params: {
    location: location
    deploymentId: deploymentId
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceResourceId: laws.outputs.id
    servicesSubnetResourceId: vnet.outputs.servicesSubnetResourceId
    vnetResourceId: vnet.outputs.id
    tags: tags
  }
}

module appGwPip 'modules/publicIpAddress/publicIpAddress.bicep' = {
  name: appGatewayPublicIpDeploymentName
  params: {
    location: location
    publicIpAddressName: appGatewayPublicIpName
    tags: tags
    dnsLabel: appGatewayPublicIpName
  }
}
