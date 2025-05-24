Remove-Item -Path ".\azure_imagebuilder" -Recurse -Force

$resourceGroups = az group list --query "[].name" --output tsv
'Total Resource groups count ' + $resourceGroups.COUNT
'Resource groups List --'
$resourceGroups
'Resource groups Delete in Progress --'
foreach ($group in $resourceGroups) {
    Write-Host "Selected ResourceGroup Name" $group 
    az group delete --name $group #--yes   
}

$templateUrl = "https://raw.githubusercontent.com/azure/azvmimagebuilder/main/solutions/14_Building_Images_WVD/armTemplateWVD.json"
$templateFilePath = "armTemplateWVD.json"