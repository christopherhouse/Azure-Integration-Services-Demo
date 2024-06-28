using '../02-main.bicep'

// Resource name format = {workloadName}-{environmentSuffix}-{resourceType}
// e.g. Resource name for a key vault: myworkload-dev-kv (integration-dev-kv)
param workloadName = 'bw-ais'
param environmentSuffix = 'loc'
param location = 'eastus2'
param apimSkuName = 'Developer'
param apimSkuCapacity = 1
param apimPublisherEmailAddress = 'chhouse@microsoft.com'
param apimPublisherOrganizationName = 'Contoso'
param apimVnetIntegrationMode = 'Internal'
param virtualNetworkName = 'bw-ais-loc-vnet'
param apimSubnetName = 'apim'
param aseSubnetName = 'ase'
param servicesSubnetName = 'services'
param appGatewaySubnetName = 'appGw'
param appInsightsConnectionStringKeyVaultSecretName = 'appInsightsConnectionString'
param internalApimGatewayHostPrivateIp = '10.0.5.254'
param keyVaultName = 'bw-ais-loc-kv'
param logAnalyticsWorkspaceName = 'bw-ais-loc-laws'
param enableZoneRedundancy = false
param tags = {
  Workload: 'Integration Platform'
  Environment: environmentSuffix
  CostCenter: 'A-012345-6789'
  Owner: 'Chris House'
  OwnerEmail: 'madeup-email@microsoft.net'
}
param minAppGatewayCapacity = 2
param maxAppGatewayCapacity = 3
param logicAppAppServicePlanSku = 'I1v2'
param logicAppAppServicePlanSkuCount = 1
param externalApimHostNameDnsConfiguration = {
  zoneName: 'chrishou.se'
  hostName: 'api.bw'
  certificateKeyVaultUri: 'https://bw-ais-loc-kv.vault.azure.net/secrets/api-bw-chrishou-se'
  deployCustomHostName: true
}
param internalApimHostnameDnsConfiguration = {
  zoneName: 'chrishou.se'
  hostName: 'internal.api.bw'
  certificateKeyVaultUri: 'https://bw-ais-loc-kv.vault.azure.net/secrets/internal-api-bw-chrishou-se'
  deployCustomHostName: true
}
param appGatewayPublicIpName = 'bw-ais-loc-appgw-pip'
param appGatewayWafMode = 'Prevention'
param appServicePlans = [
  {
    appServicePlanNameSuffix: 'ordering'
    appServicePlanSku: 'I1v2'
    contributorGroupObjectId: '178c2375-7954-4c64-a9cf-8f81443e993c'
    instanceCount: 1
    zones: ['1']
    resourceGroupName: 'BW-AIS-ORDERING-DEV'
    tags: {
      Workload: 'Integration Platform'
      Environment: environmentSuffix
      CostCenter: 'A-012345-6789'
      Owner: 'Chris House'
      OwnerEmail: 'chhouse@microsoft.com'
    }
  }
  {
    appServicePlanNameSuffix: 'catalog'
    appServicePlanSku: 'I1v2'
    contributorGroupObjectId: '11871994-5b79-4ff7-8b8d-4234d9283d33'
    instanceCount: 1
    zones: ['1']
    resourceGroupName: 'BW-AIS-CATALOG-DEV'
    tags: {
      Workload: 'Integration Platform'
      Environment: environmentSuffix
      CostCenter: 'F-982578-9876'
      Owner: 'Chris House'
      OwnerEmail: 'chhouse@microsoft.com'
    }
  }  
]
