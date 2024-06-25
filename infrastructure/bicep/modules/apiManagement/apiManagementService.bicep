import * as udt from '../userDefined/userDefinedTypes.bicep'

@description('The name of the API Management resource that will be created')
param apiManagementServiceName string

@description('The region where the new API Management resource will be created')
param location string

@description('The name of the SKU to provision')
@allowed(['Developer', 'Premium', 'StandardV2']) // Only allow SKUs that support vnet integration
param skuName string

@description('The number of scale units to provision')
param skuCapacity int

@description('The email address associated with the publisher.  This value can be used as the send-from address for email notifications')
param publisherEmailAddress string

@description('THe name of that API publisher\'s organization.  This value is used in the developer portal and for email notifications')
param publisherOrganizationName string

@description('The vnet integration mode, internal for no public gateway endpoint, external to include a public gateway endpoint')
@allowed(['External', 'Internal'])
param vnetIntegrationMode string

@description('The resource id of the subnet to integrate with')
param vnetSubnetResourceId string

@description('The resource id of the public IP address that will be attached to APIM')
param publicIpResourceId string

@description('The resource id of the user assigned managed identity that will be used to access the key vault')
param userAssignedManagedIdentityResourceId string

@description('The principal id of the user assigned managed identity that will be used to access the key vault')
param userAssignedManagedIdentityPrincipalId string

@description('The name of the key vault that will be used to store secrets')
param keyVaulName string

@description('The resource id of the log analytics workspace that will be used to store diagnostic logs')
param logAnalyticsWorkspaceId string

@description('The resource id of the virtual network that will be used to integrate with APIM')
param vnetResourceId string

@description('A flag indicating whether the APIM instance should be zone redundant')
param zoneRedundant bool = false

@description('The unique identifier for the deployment')
param buildId string

@description('The tags to apply to the resources')
param tags object = {}

param systemAssignedManagedIdentityPrincipalId string = ''

param internalHostnameDnsConfiguration udt.apiManagementDnsConfiguration

param externalHostNameDnsConfiguration udt.apiManagementDnsConfiguration

var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'
var kvCertificateUserRoleId = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'

var zones = zoneRedundant ? ['1', '2', '3'] : []

var externalHostName = externalHostNameDnsConfiguration.deployCustomHostName ? [{
    hostName: '${externalHostNameDnsConfiguration.hostName}.${externalHostNameDnsConfiguration.zoneName}'
    keyVaultId: externalHostNameDnsConfiguration.certificateKeyVaultUri
    identityClientId: systemAssignedManagedIdentityPrincipalId
    type: 'Proxy'
    certificateSource: 'KeyVault'  
}] : []

var internalHostName = internalHostnameDnsConfiguration.deployCustomHostName ? [{
    hostName: '${internalHostnameDnsConfiguration.hostName}.${internalHostnameDnsConfiguration.zoneName}'
    keyVaultId: internalHostnameDnsConfiguration.certificateKeyVaultUri
    identityClientId: systemAssignedManagedIdentityPrincipalId
    type: 'Proxy'
    certificateSource: 'KeyVault'
}] : []

var hostNames = union(externalHostName, internalHostName)

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaulName
  scope: resourceGroup()
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: kvSecretsUserRoleId
  scope: subscription()
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, kvSecretsUserRoleId, userAssignedManagedIdentityPrincipalId)
  scope: kv
  properties: {
    principalId: userAssignedManagedIdentityPrincipalId
    roleDefinitionId: kvSecretsUserRole.id
    principalType: 'ServicePrincipal'
  }
}

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apiManagementServiceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityResourceId}': {}
    }
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    apiVersionConstraint: {
      minApiVersion: '2021-08-01'
    }
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA' : 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256' : 'False'
    }
    hostnameConfigurations: hostNames
    publisherEmail: publisherEmailAddress
    publisherName: publisherOrganizationName
    virtualNetworkType: vnetIntegrationMode
    virtualNetworkConfiguration: {
      subnetResourceId: vnetSubnetResourceId
    }
    publicIpAddressId: publicIpResourceId
  }
  zones: zones
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: apiManagementService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
  }
}

module dns '../dns/privateDnsZone.bicep' = {
  name: '${apiManagementService.name}-dns-${buildId}'
  params: {
    vnetResourceId: vnetResourceId
    zoneName: 'azure-api.net'
    tags: tags
  }
}

module aRecords '../dns/aRecord.bicep' = {
  name: '${apiManagementService.name}-dns-a-records-${buildId}'
  params: {
    zoneName: dns.outputs.zoneName
    ipAddress: apiManagementService.properties.privateIPAddresses[0]
    recordNames: [
      apiManagementService.name
      '${apiManagementService.name}.protal'
      '${apiManagementService.name}.management'
      '${apiManagementService.name}.scm'
    ]
  }
}

module intDns '../dns/privateDnsZone.bicep' = if(!empty(internalHostnameDnsConfiguration)) {
  name: '${apiManagementService.name}-int-dns-${buildId}'
  params: {
    vnetResourceId: vnetResourceId
    zoneName: internalHostnameDnsConfiguration.zoneName
    tags: tags
  }
}

module extDns '../dns/privateDnsZone.bicep' = if(!empty(externalHostNameDnsConfiguration)) {
  name: '${apiManagementService.name}-ext-dns-${buildId}'
  params: {
    vnetResourceId: vnetResourceId
    zoneName: externalHostNameDnsConfiguration.zoneName
    tags: tags
  }
  dependsOn: [
    intDns
  ]
}

module intDnsRecord '../dns/aRecord.bicep' = if(!empty(internalHostnameDnsConfiguration)) {
  name: '${apiManagementService.name}-int-dns-a-records-${buildId}'
  params: {
    zoneName: intDns.outputs.zoneName
    ipAddress: apiManagementService.properties.privateIPAddresses[0]
    recordNames: [
      internalHostnameDnsConfiguration.hostName
    ]
  }
}

module extDnsRecord '../dns/aRecord.bicep' = if(!empty(externalHostNameDnsConfiguration)) {
  name: '${apiManagementService.name}-ext-dns-a-records-${buildId}'
  params: {
    zoneName: extDns.outputs.zoneName
    ipAddress: apiManagementService.properties.privateIPAddresses[0]
    recordNames: [
      externalHostNameDnsConfiguration.hostName
    ]
  }
}

resource smi 'Microsoft.ManagedIdentity/identities@2023-07-31-preview' existing = {
  name: 'default'
  scope: apiManagementService
}

resource kvCertificateUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: kvCertificateUserRoleId
  scope: subscription()
}

resource kvRoleAssignmentSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, kvSecretsUserRoleId, apiManagementService.id)
  scope: kv
  properties: {
    principalId: smi.properties.clientId
    roleDefinitionId: kvSecretsUserRole.id
    principalType: 'ServicePrincipal'
  }
}

resource kvSMICertRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, kvCertificateUserRoleId, apiManagementService.id)
  scope: kv
  properties: {
    principalId: smi.properties.clientId
    roleDefinitionId: kvCertificateUserRole.id
    principalType: 'ServicePrincipal'
  }
}

output id string = apiManagementService.id
output name string = apiManagementService.name
output privateIpAddress string = apiManagementService.properties.privateIPAddresses[0]
output defaultHostName string = apiManagementService.properties.hostnameConfigurations[0].hostName
output systemAssignedManagedIdentityPrincipalId string = apiManagementService.identity.principalId
output systemAssignedManagedIdentityClientId string = smi.properties.clientId
