@description('The name of the user assigned managed identity to create')
param managedIdentityName string

@description('The Azure region where the user assigned managed identity should be created')
param location string

@description('The tags to associate with the user assigned managed identity')
param tags object = {}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  tags: tags
  location: location
}

output id string = uami.id
output name string = uami.name
output principalId string = uami.properties.principalId
output clientId string = uami.properties.clientId
