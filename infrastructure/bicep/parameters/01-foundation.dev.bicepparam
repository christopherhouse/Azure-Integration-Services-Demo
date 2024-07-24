using '../01-foundation.bicep'
param workloadName = 'bw-ais'
param environmentSuffix = 'loc'
param location = 'eastus2'
param addressPrefixes = ['10.0.0.0/8']
param subnetConfigurations = {
  apimSubnet: {
    name: 'apim'
    addressPrefix: '10.0.1.0/24'
  }
  runnersSubnet: {
    name: 'runners'
    addressPrefix: '10.0.2.0/24'
  }
  servicesSubnet: {
    name: 'services'
    addressPrefix: '10.0.3.0/24'
  }
  aseSubnet: {
    name: 'ase'
    addressPrefix: '10.0.6.0/24'
  }
  appGwSubnet: {
    name: 'appGw'
    addressPrefix: '10.0.5.0/24'
  }
  bastionSubnet: {
    name: 'AzureBastionSubnet'
    addressPrefix: '10.0.0.0/26'
  }
}
param logAnalyticsRetentionDays = 90
param tags = {
  Workload: 'Integration Platform'
  Environment: environmentSuffix
  CostCenter: 'A-012345-6789'
  Owner: 'Chris House'
  OwnerEmail: 'madeup-email@microsoft.net'
}
param appGatewayPrivateIpAddress = '10.0.5.254'
