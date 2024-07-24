param(
    [string]
    [Parameter(Mandatory=$true)]
    [CmdletBinding()]
    $ResourceGroupName,
    [string]
    [Parameter(Mandatory=$true)]
    [CmdletBinding()]
    $EnvironmentName
)

# create a variable named $deploymentName and set it to a unique value, the first 8 characters of a new guid
$deploymentName = (New-Guid).Guid.Substring(0,8)

az deployment group create --name $deploymentName `
                           --template-file ..\bicep\01-foundation.bicep `
                           -g $ResourceGroupName `
                           --parameters ..\bicep\parameters\01-foundation.$EnvironmentName.bicepparam
