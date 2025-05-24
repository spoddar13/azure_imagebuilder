#Connect-AzAccount



#Timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Step 1: Import module
Import-Module Az.Accounts

# Step 2: get existing context
$currentAzContext = Get-AzContext

# Destination image resource group
$imageResourceGroup = "RG" + $timestamp

# Location (see possible locations in the main docs)
$location = "centralindia"

# Your subscription. This command gets your current subscription
#Set Subscription
$subscriptionID = (Get-AzContext).Subscription.Id
Set-AzContext -SubscriptionId $subscriptionID

# Image template name
$imageTemplateName = "avd10ImageTemplate01"

# Distribution properties object name (runOutput). Gives you the properties of the managed image on completion
$runOutputName = "sigOutput"

# Create resource group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

#setup role def names, these need to be unique
$timeInt = $(get-date -UFormat "%s")
$imageRoleDefName = "Azure Image Builder Image Def" + $timestamp
$identityName = "aibIdentity" + $timestamp

## Add Azure PowerShell modules to support AzUserAssignedIdentity and Azure VM Image Builder
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object { Install-Module -Name $_ -AllowPrerelease }

# Create the identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName -Location $location

$identityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId



$aibRoleImageCreationUrl = "https://raw.githubusercontent.com/spoddar13/azure_imagebuilder/main/RoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# Download the config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# Create a role definition
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# Grant the role definition to the VM Image Builder service principal
New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

