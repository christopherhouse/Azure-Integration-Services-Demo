$files = Get-ChildItem -Path .\*.bicepparam -Recurse

foreach ($file in $files) {
    $outputFileName = $file.Name.Replace(".bicepparam", ".json")
    $inputFileName = $file.Name
    Write-Host "Generating file $outputFileName from $inputFileName"
    bicep build-params $file
}
