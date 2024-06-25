import * as apimType from './modules/apiManagement/apiManagementService.bicep'
import * as subnetTypes from './modules/virtualNetwork/virtualNetwork.bicep'
import * as udt from './modules/userDefined/userDefinedTypes.bicep'

@description('The name of this workload.  This is used for computing resource names in the form of <workloadName>-<environmentSuffix>-<resource type>')
param workloadName string

@description('The name or abbreviation of the environment where resources will be provisioned.  This is used for computing resource names in the form of <workloadName>-<environmentSuffix>-<resource type>')
param environmentSuffix string

@description('The region resources will be provisioned in')
param location string

@description('The name of the Key Vault that will be used for secrets and certificates')
param keyVaultName string

@description('The resource id of the Log Analytics workspace that will be used for monitoring and diagnostics')
param logAnalyticsWorkspaceName string

@description('The name of the virtual network this template will deploy subnets into')
param virtualNetworkName string

@description('The name of the subnet that will be used for the API Management service')
param apimSubnetName string

@description('The name of the subnet that will be used for supporting services (storage, key vault, etc)')
param servicesSubnetName string

@description('The resource id of for the ASE subnet')
param aseSubnetName string

@description('The name of the subnet that will be used for the App Gateway')
param appGatewaySubnetName string

@description('The name of the API Management SKU to provision')
@allowed(['Developer', 'Premium', 'StandardV2'])
param apimSkuName string

@description('The DNS configuration for the internal APIM hostname')
param internalApimHostnameDnsConfiguration udt.apiManagementDnsConfiguration

@description('The DNS configuration for the external APIM hostname')
param externalApimHostNameDnsConfiguration udt.apiManagementDnsConfiguration

@description('The number of scale units to provision')
param apimSkuCapacity int = 1

@description('The email address associated with the publisher.  This value can be used as the send-from address for email notifications')
param apimPublisherEmailAddress string

@description('THe name of that API publisher\'s organization.  This value is used in the developer portal and for email notifications')
param apimPublisherOrganizationName string

@description('The vnet integration mode, internal for no public gateway endpoint, external to include a public gateway endpoint')
@allowed(['Internal', 'External'])
param apimVnetIntegrationMode string

@description('The URI of the Key Vault secret containing the App Inisghts connection string')
param appInsightsConnectionStringKeyVaultSecretName string

@description('The private IP APIM will use')
param internalApimGatewayHostPrivateIp string

@description('The minimum capacity for the App Gateway')
param minAppGatewayCapacity int

@description('The maximum capacity for the App Gateway')
param maxAppGatewayCapacity int

@description('The name of the SKU to use for the Logic App App Service Plan')
param logicAppAppServicePlanSku udt.isolatedAppServicePlanSku

@description('The number of instances to provision for the Logic App App Service Plan')
param logicAppAppServicePlanSkuCount int

@description('The name of the public IP address for the App Gateway service')
param appGatewayPublicIpName string

@allowed(['Prevention', 'Detection'])
@description('The WAF mode to use for the App Gateway')
param appGatewayWafMode string

@description('The build ID that deployed this template.  Used to generate a unique deployment name in Azure')
param buildId string = substring(uniqueString(utcNow()), 0, 4)

@description('Whether or not to enable zone redundancy for applicable services')
param enableZoneRedundancy bool = false

@description('Tags to be applied to resources deployed in this template')
param tags object = {}

// APIM
var apimName = '${workloadName}-${environmentSuffix}-apim'
var apimIdentityName = '${apimName}-uami'
var apimPublicIpName = '${apimName}-pip'
var apimUamiName = '${apimName}-uami'
var apimDeploymentName = '${apimName}-${buildId}'
var apimUamiDeploymentName = '${apimUamiName}-${buildId}'
var apimPublicIpDeploymentName = '${apimPublicIpName}-${buildId}'

// Storage DNS
var storageDnsDeploymentName = 'storage-private-dns-${buildId}'

// ASE
var aseName = '${workloadName}-${environmentSuffix}-ase'
var asedeploymentName = '${aseName}-${buildId}'
var aseDnsDeploymentName = 'asedns-${buildId}'

// ASP
var aspName = '${workloadName}-${environmentSuffix}-asp'
var aspDeploymentName = '${aspName}-${buildId}'

// Logic Ap
var logicAppName = '${workloadName}-${environmentSuffix}-la'

// Service Bus Namespace
var sbNamespaceName = '${workloadName}-${environmentSuffix}-sbns'
var sbNamespaceDeploymentName = '${sbNamespaceName}-${buildId}'

// App Gateway and WAF
var wafPolicyName = '${workloadName}-${environmentSuffix}-waf'
var wafPolicyDeploymentName = '${wafPolicyName}-${buildId}'

var appGwName = '${workloadName}-${environmentSuffix}-appgw'
var appGwDeploymentName = '${appGwName}-${buildId}'

// URI to the App Insights connection string in Key Vault
var appInsightsConnectionStringSecretUri = formatKeyVaultSecretUri(keyVaultName, appInsightsConnectionStringKeyVaultSecretName)

// For a given key vault name and secret name, construct a secret URI
func formatKeyVaultSecretUri(vaultName string, secretName string) string => 'https://${vaultName}${environment().suffixes.keyvaultDns}/secrets/${secretName}'

// Existing resources from 01-foundation.bicep
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup()
}

resource apimSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: apimSubnetName
  parent: vnet
}

resource aseSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: aseSubnetName
  parent: vnet
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: servicesSubnetName
  parent: vnet
}

resource appGwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: appGatewaySubnetName
  parent: vnet
}

resource laws 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup()
}

// User assigned managed identity for APIM
module apimUami './modules/managedIdentity/userAssignedManagedIdentity.bicep' = {
  name: apimUamiDeploymentName
  params: {
    location: location
    managedIdentityName: apimIdentityName
    tags: tags
  }
}

// Public IP required by APIM
module apimPip './modules/publicIpAddress/publicIpAddress.bicep' = {
  name: apimPublicIpDeploymentName
  params: {
    location: location
    publicIpAddressName: apimPublicIpName
    dnsLabel: apimName
    tags: tags
  }
}

// API Management Service
module apim './modules/apiManagement/apiManagementService.bicep' = {
  name: apimDeploymentName
  params: {
    location: location
    externalHostNameDnsConfiguration: externalApimHostNameDnsConfiguration
    internalHostnameDnsConfiguration: internalApimHostnameDnsConfiguration
    apiManagementServiceName: apimName
    skuName: apimSkuName
    skuCapacity: apimSkuCapacity
    publisherEmailAddress: apimPublisherEmailAddress
    publisherOrganizationName: apimPublisherOrganizationName
    vnetIntegrationMode: apimVnetIntegrationMode
    vnetSubnetResourceId: apimSubnet.id
    publicIpResourceId: apimPip.outputs.id
    userAssignedManagedIdentityResourceId: apimUami.outputs.id
    keyVaulName: keyVaultName
    userAssignedManagedIdentityPrincipalId: apimUami.outputs.principalId
    logAnalyticsWorkspaceId: laws.id
    vnetResourceId: vnet.id
    buildId: buildId
    zoneRedundant: enableZoneRedundancy
    tags: tags
  }
}

// Private DNS Zones for Storage
module storageDns './modules/storage/storagePrivateDns.bicep' = {
  name: storageDnsDeploymentName
  params: {
    buildId: buildId
    vnetResourceId: vnet.id
    tags: tags
  }
}

module ase './modules/appService/appServiceEnvironmentV3.bicep' = {
  name: asedeploymentName
  params: {
    location: location
    aseName: aseName
    aseSubnetResourceId: aseSubnet.id
    logAnalyticsWorkspaceResourceId: laws.id
    tags: tags
  }
}

module aseDns './modules/dns/privateDnsZone.bicep' = {
  name: aseDnsDeploymentName
  params: {
    zoneName: ase.outputs.dnsSuffix
    vnetResourceId: vnet.id
    tags: tags
  }
}

module asp './modules/appService/appServicePlan.bicep' = {
  name: aspDeploymentName
  params: {
    location: location
    appServicePlanName: aspName
    aseResourceId: ase.outputs.id
    skuName: logicAppAppServicePlanSku
    skuCapacity: logicAppAppServicePlanSkuCount
    zoneRedundant: enableZoneRedundancy
    tags: tags
  }
}

module logicApp './modules/appService/privateLogicApp.bicep' = {
  name: '${logicAppName}-${buildId}'
  params: {
    location: location
    logicAppName: logicAppName
    appServicePlanResourceId: asp.outputs.id
    aseResourceId: ase.outputs.id
    blobDnsZoneResourceId: storageDns.outputs.blobDnsZoneId
    tableDnsZoneResourceId: storageDns.outputs.tableDnsZoneId
    queueDnsZoneResourceId: storageDns.outputs.queueDnsZoneId
    fileDnsZoneResourceId: storageDns.outputs.fileDnsZoneId
    buildId: buildId
    storageSubnetResourceId: servicesSubnet.id
    keyVaultName: keyVaultName
    appInsightsConnectionStringSecretUri: appInsightsConnectionStringSecretUri
    logAnalyticsWorkspaceResourceId: laws.id
    zoneRedundantStorage: enableZoneRedundancy
    tags: tags
  }
}

module sbns './modules/serviceBus/privateServiceBusNamespace.bicep' = {
  name: sbNamespaceDeploymentName
  params: {
    buildId: buildId
    capacityUnits: 1
    deployPrivateDns: true
    location: location
    logAnalyticsWorkspaceResourceId: laws.id
    serviceBusNamespaceName: sbNamespaceName
    subnetResourceId: servicesSubnet.id
    vnetResourceId: vnet.id
    tags: tags
  }
}

// WAF Policy
module waf './modules/waf/wafPolicy.bicep' = {
  name: wafPolicyDeploymentName
  params: {
    location: location
    wafPolicyName: wafPolicyName
    tags: tags
    wafMode: appGatewayWafMode
  }
}

// App Gateway
module appGw './modules/applicationGateway/applicationGateway.bicep' = {
  name: appGwDeploymentName
  params: {
    appGatewayName: appGwName
    location: location
    subnetResourceId: appGwSubnet.id
    logAnalyticsWorkspaceResourceId: laws.id
    keyVaultName: keyVaultName
    internalGatewayHostPrivateIp: internalApimGatewayHostPrivateIp
    tags: tags
    minAppGatewayCapacity: minAppGatewayCapacity
    maxAppGatewayCapacity: maxAppGatewayCapacity
    internalEndpointHostName: '${internalApimHostnameDnsConfiguration.hostName}.${internalApimHostnameDnsConfiguration.zoneName}'
    internalEndpointTlsCertificateId: internalApimHostnameDnsConfiguration.certificateKeyVaultUri
    exteralEndpointTlsCertificateId: externalApimHostNameDnsConfiguration.certificateKeyVaultUri
    externalEndpointHostName: '${externalApimHostNameDnsConfiguration.hostName}.${externalApimHostNameDnsConfiguration.zoneName}'
    appGatewayPublicIpName: appGatewayPublicIpName
    wafPolicyResourceId: waf.outputs.id
  }
}
