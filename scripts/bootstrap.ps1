# ============================================================================
# Bootstrap Script (PowerShell) - OPTIONAL LOCAL ALTERNATIVE
# ============================================================================
#
# This script is for LOCAL DEVELOPMENT ONLY.
# For production use, prefer the GitHub Actions workflow:
#   .github/workflows/bootstrap.yml
#
# Prerequisites:
#   - Azure CLI installed (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
#   - Logged in to Azure (run: az login)
#
# Usage:
#   .\scripts\bootstrap.ps1 -Environment dev -Region eastus
#
# ============================================================================

param(
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [string]$Region = "eastus",
    
    [string]$OrgShort = "tv",
    
    [string]$Project = "legal"
)

$ErrorActionPreference = "Stop"

# Generate resource names
$RgName = "$OrgShort-$Project-$Environment-tfstate-rg"
$StorageName = "$OrgShort$Project$($Environment)tfstate"
$ContainerName = "tfstate"

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "  Terraform State Bootstrap (Local)" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE: For CI/CD, use the GitHub Actions workflow instead:" -ForegroundColor Cyan
Write-Host "      .github/workflows/bootstrap.yml" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment:     $Environment"
Write-Host "Region:          $Region"
Write-Host "Resource Group:  $RgName"
Write-Host "Storage Account: $StorageName"
Write-Host "Container:       $ContainerName"
Write-Host ""

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Gray
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "Subscription: $($account.name)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Not logged in to Azure." -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Creating resources..." -ForegroundColor Yellow

# Create Resource Group
Write-Host "  [1/4] Creating resource group..." -ForegroundColor Gray
az group create `
    --name $RgName `
    --location $Region `
    --tags environment=$Environment purpose=terraform-state managed_by=local-script `
    --output none

# Create Storage Account
Write-Host "  [2/4] Creating storage account..." -ForegroundColor Gray
az storage account create `
    --name $StorageName `
    --resource-group $RgName `
    --location $Region `
    --sku Standard_LRS `
    --kind StorageV2 `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false `
    --output none

# Create Blob Container
Write-Host "  [3/4] Creating blob container..." -ForegroundColor Gray
az storage container create `
    --name $ContainerName `
    --account-name $StorageName `
    --auth-mode login `
    --output none

# Enable Versioning
Write-Host "  [4/4] Enabling versioning..." -ForegroundColor Gray
az storage account blob-service-properties update `
    --account-name $StorageName `
    --resource-group $RgName `
    --enable-versioning true `
    --output none

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  BOOTSTRAP COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Update envs/$Environment/backend.hcl with:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  resource_group_name  = `"$RgName`""
Write-Host "  storage_account_name = `"$StorageName`""
Write-Host "  container_name       = `"$ContainerName`""
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update the backend.hcl file with the values above"
Write-Host "  2. Deploy stacks in order: foundation -> network -> security -> ..."
Write-Host ""
