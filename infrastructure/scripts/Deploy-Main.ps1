param (
    [CmdletBinding()]
    [Parameter()]
    [string]
    $EnvironmentName,
    [CmdletBinding()]
    [Parameter()]
    [string]
    $ResourceGroupName
)

Write-Host "** Deploying main bicep template"

# create a variable named $deploymentName and set it to a unique value, the first 8 characters of a new guid
$deploymentName = (New-Guid).Guid.Substring(0,8)

az deployment group create --name $deploymentName `
                           --template-file ..\bicep\02-main.bicep `
                           -g $ResourceGroupName `
                           --parameters ..\bicep\parameters\02-main.$EnvironmentName.bicepparam