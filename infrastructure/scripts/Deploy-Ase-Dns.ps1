param(
    [CmdletBinding()]
    [Parameter(Mandatory = $true)]
    [string]
    $AseName,
    [CmdletBinding()]
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
)

$ttl = 3600
$zoneName = "$AseName.appserviceenvironment.net"

Write-Host "** Getting the internal IP address of the ASE"
# Powershell cmdlet for ASE doesn't return IP information, so using az cli instead :(
az appservice ase show --name $AseName --query "networkingConfiguration.internalInboundIpAddresses[0]" -o tsv | Tee-Object -Variable internalIp

Write-Host "** ASE internal inbound IP address: $internalIp"
Write-Host "** Creating DNS zone named $zoneName"

New-AzPrivateDnsZone -Name $zoneName -ResourceGroupName $ResourceGroupName

Write-Host "Created DNS zone $zoneName, creating records for ASE"

New-AzPrivateDnsRecordSet -Name "*" `
                          -RecordType "A" `
                          -ZoneName $zoneName `
                          -ResourceGroupName $ResourceGroupName `
                          -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -Ipv4Address $internalIp) `
                          -Ttl $ttl

Write-Host "Created A record *, pointing to $internalIp"

New-AzPrivateDnsRecordSet -Name "@" `
                          -RecordType "A" `
                          -ZoneName $zoneName `
                          -ResourceGroupName $ResourceGroupName `
                          -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -Ipv4Address $internalIp) `
                          -Ttl $ttl

Write-Host "Created A record @, pointing to $internalIp"

New-AzPrivateDnsRecordSet -Name "*.scm" `
                          -RecordType "A" `
                          -ZoneName $zoneName `
                          -ResourceGroupName $ResourceGroupName `
                          -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -Ipv4Address $internalIp) `
                          -Ttl $ttl

Write-Host "Created A record *.scm, pointing to $internalIp"

Write-Host "DNS zone and records created for ASE $AseName"