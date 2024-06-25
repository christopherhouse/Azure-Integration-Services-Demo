@export()
func formatKeyVaultSecretUri(vaultName string, secretName string) string => 'https://${vaultName}${environment().suffixes.keyvaultDns}/secrets/${secretName}'

@export()
func formatAppServiceKeyVaultReference(secretUri string) string => '@Microsoft.KeyVault(SecretUri=${secretUri})'
