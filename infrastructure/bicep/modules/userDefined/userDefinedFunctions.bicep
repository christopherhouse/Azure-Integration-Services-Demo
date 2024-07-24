@export()
@description('Returns a URI pointing to a Key Vault secret')
func formatKeyVaultSecretUri(vaultName string, secretName string) string => 'https://${vaultName}${environment().suffixes.keyvaultDns}/secrets/${secretName}'

@export()
@description('Returns a Key Vault reference setting value for an App Service')
func formatAppServiceKeyVaultReference(secretUri string) string => '@Microsoft.KeyVault(SecretUri=${secretUri})'
