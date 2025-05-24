#Login
#Connect-AzAccount

#Set Subscription ...
$subscriptionID = (Get-AzContext).Subscription.Id
Set-AzContext -SubscriptionId $subscriptionID

#Register Providers

Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages, Microsoft.Network, Microsoft.ManagedIdentity |
Where-Object RegistrationState -ne Registered |
Register-AzResourceProvider

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
# Destination image resource group name
$imageResourceGroup = 'RG-TEST-01-' + $timestamp

# Azure region
$location = 'centralindia'

# Name of the image to be created
$imageTemplateName = 'myWinImage'

# Distribution properties of the managed image upon completion
$runOutputName = 'myDistResults'

# Your Azure Subscription ID
$subscriptionID = (Get-AzContext).Subscription.Id
Write-Output $subscriptionID


##Create Resource Group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

#Create variables for the role definition and identity names. These values must be unique.
#[int]$timeInt = $(Get-Date -UFormat '%s')
#$imageRoleDefName = "Azure Image Builder Image Def $timeInt"
$imageRoleDefName = "AzureImageBuilderCustomRole-" + $timestamp
#$identityName = "myIdentity$timeInt"
$identityName = "myIdentity001"

#Create a user identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName -Location $location

#Store the identity resource and principal IDs in variables
$identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

#Downlaod JSON config file to assign permissions to the identity
$myRoleImageCreationUrl = 'https://raw.githubusercontent.com/spoddar13/azure_imagebuilder/main/RoleImageCreation.json'
$myRoleImageCreationPath = "myRoleImageCreation.json"
Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing


#update role definition template
$Content = Get-Content -Path $myRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $imageResourceGroup
$Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
$Content | Out-File -FilePath $myRoleImageCreationPath -Force

#Create role definition
New-AzRoleDefinition -InputFile $myRoleImageCreationPath

#Grant the role definition to the VM Image Builder service principal
$RoleAssignParams = @{
    ObjectId           = $identityNamePrincipalId
    RoleDefinitionName = $imageRoleDefName
    Scope              = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
}
New-AzRoleAssignment @RoleAssignParams

#Remove-Item ".\RoleImageCreation.json"

#Download the image configuration template
$myImageCreationUrl = 'https://raw.githubusercontent.com/spoddar13/azure_imagebuilder/main/ImageTemplateWin.json'
$myImageCreationPath = "NewImageTemplateWin.json"

Invoke-WebRequest -Uri $myImageCreationUrl -OutFile $myImageCreationPath -UseBasicParsing

#$myImageCreationPath = '.\ImageTemplateWin.json'

#update role definition template
$Content1 = Get-Content -Path $myImageCreationPath -Raw
$Content1 = $Content1 -replace '<subscriptionID>', $subscriptionID
$Content1 = $Content1 -replace '<rgName>', $imageResourceGroup
$Content1 = $Content1 -replace '<region>', $location
$Content1 = $Content1 -replace '<imageName>', $imageTemplateName
$Content1 = $Content1 -replace '<runOutputName>', $runOutputName
$Content1 = $Content1 -replace '<imgBuilderId>', $imgBuilderId
$Content1 | Out-File -FilePath $myImageCreationPath -Force

az resource create --resource-group $imageResourceGroup --properties $myImageCreationPath --is-full-object --resource-type Microsoft.VirtualMachineImages/imageTemplates -n ImageTemplateWin2019
