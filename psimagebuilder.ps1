#Connect-AzAccount

#Set Subscription
$subscriptionID = (Get-AzContext).Subscription.Id
Set-AzContext -SubscriptionId $subscriptionID

#Timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Destination image resource group name
$imageResourceGroup = 'RG-' + $timestamp

# Azure region
$location = 'centralindia'

# Name of the image to be created
$imageTemplateName = 'myWinImage'

# Distribution properties of the managed image upon completion
$runOutputName = 'myDistResults'

# Your Azure Subscription ID
$subscriptionID = (Get-AzContext).Subscription.Id
Write-Output $subscriptionID

New-AzResourceGroup -Name $imageResourceGroup -Location $location

$imageRoleDefName = "Azure Image Builder Image Def $timestamp"
$identityName = "myIdentity$timestamp"

New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName -Location $location

$identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId


$myRoleImageCreationUrl = 'https://raw.githubusercontent.com/spoddar13/azure_imagebuilder/main/RoleImageCreation.json'
$myRoleImageCreationPath = "myRoleImageCreation.json"

Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing

$Content = Get-Content -Path $myRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $imageResourceGroup
$Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
$Content | Out-File -FilePath $myRoleImageCreationPath -Force

# setup role def names, these need to be unique
$imageRoleDefName = "Azure Image Builder Image Def" + $timestamp
$identityName = "aibIdentity" + $timestamp

## Add Azure PowerShell modules to support AzUserAssignedIdentity and Azure VM Image Builder
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object { Install-Module -Name $_ -AllowPrerelease }

# Create the identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName -Location $location

$identityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

