@export()
@description('User defined type for App Service Isolated SKUs')
type isolatedAppServicePlanSku = 'I1v2' | 'I1mv2' | 'I2v2' | 'I2mv2' | 'I3v2' | 'I3mv2' | 'I4v2' | 'I4mv2' | 'I5v2' | 'I5mv2' | 'I6v2'

@export()
@description('Supported language workers for Function Apps')
type functionWorkerRuntimes = 'dotnet' | 'node' | 'python' | 'java' | 'powershell'

@export()
@description('Defines file share configuration')
type filShareConfigurationType = {
  shareName: string
  quota: int
}

@export()
@description('Array of file share configurations')
type fileSharesConfiguration = filShareConfigurationType[]

@export()
@description('Custom DNS configuration for API Management hostnames')
type apiManagementDnsConfiguration = {
  zoneName: string
  hostName: string
  certificateKeyVaultUri: string
}
