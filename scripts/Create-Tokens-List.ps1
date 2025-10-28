<#
.SYNOPSIS
    EVBoise SharePoint List Creator – Creates or verifies the "Tokens" list in the EVBoise SharePoint site.

.DESCRIPTION
    This script connects to the EVBoise SharePoint tenant using credentials stored in a local `.env` file
    and ensures that the "Tokens" list exists with the proper structure. 
    It does NOT import or upload data — it only creates the list and columns.

    The `.env` file should contain the following keys:
        EVBOISE_SITE_URL=https://evboise.sharepoint.com/sites/EVBoiseFleet
        EVBOISE_TENANT_ID=<your-tenant-id>
        EVBOISE_CLIENT_ID=<your-client-id>

    You’ll be prompted interactively to sign in via Microsoft 365 when connecting to SharePoint.

.PARAMETERS
    None. All connection parameters are loaded from the .env file.

.NOTES
    Author: Mike Carter
    Company: EVBoise
    Created: October 2025
    Requires: 
        - PowerShell 7+
        - PnP.PowerShell module (Install-Module -Name PnP.PowerShell -Force)
        - Access to the EVBoise SharePoint tenant

.EXAMPLE
    pwsh ./Create-Tokens-List.ps1

    Connects to the EVBoise SharePoint site and ensures the Tokens list structure exists.

#>

# === CONFIGURATION ===
$EnvPath  = "C:\Users\mnc35\OneDrive\Documents\Python\.env"
$ListName = "Tokens"

# === HELPER FUNCTIONS ===
function Write-Info($msg){ Write-Host "[INFO]  $msg" }
function Write-Warn($msg){ Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err ($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

# === LOAD .ENV FILE ===
if (!(Test-Path -LiteralPath $EnvPath)) {
    throw ".env file not found at $EnvPath"
}

Write-Info "Loading environment variables from $EnvPath"
$envVars = @{}
Get-Content -LiteralPath $EnvPath | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    if ($line -match '^\s*([^=]+?)\s*=\s*(.*)$') {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim().Trim('"').Trim("'")
        $envVars[$key] = $val
    }
}

$SiteUrl  = $envVars['EVBOISE_SITE_URL']
$TenantId = $envVars['EVBOISE_TENANT_ID']
$ClientId = $envVars['EVBOISE_CLIENT_ID']

if (-not $SiteUrl -or -not $TenantId -or -not $ClientId) {
    throw "Missing required env vars (EVBOISE_SITE_URL, EVBOISE_TENANT_ID, EVBOISE_CLIENT_ID)"
}

Write-Host "--- Environment Variables Used ---"
Write-Host "EVBOISE_SITE_URL : $SiteUrl"
Write-Host "EVBOISE_CLIENT_ID: $ClientId"
Write-Host "EVBOISE_TENANT_ID: $TenantId"
Write-Host "--------------------------------"

# === CONNECT TO SHAREPOINT ===
Write-Info "Connecting to SharePoint: $SiteUrl"
try {
    Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $TenantId -Interactive -ErrorAction Stop
    Write-Info "Connected successfully."
} catch {
    Write-Err "Failed to connect: $($_.Exception.Message)"
    throw
}

# === ENSURE LIST EXISTS ===
Write-Info "Ensuring list '$ListName' exists..."
$list = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
if (-not $list) {
    Write-Info "Creating list '$ListName'..."
    New-PnPList -Title $ListName -Template GenericList -OnQuickLaunch -EnableVersioning | Out-Null
    Write-Info "List created."
} else {
    Write-Info "List '$ListName' already exists."
}

# === ENSURE FIELDS EXIST ===
$fields = @(
    @{ InternalName = "Title"; DisplayName = "Name"; Type = "Text"; Required = $true },
    @{ InternalName = "SecretValue"; DisplayName = "Secret"; Type = "Note" },
    @{ InternalName = "Scope"; DisplayName = "Scope"; Type = "Text" },
    @{ InternalName = "ExpiresAt"; DisplayName = "ExpiresAt"; Type = "DateTime" },
    @{ InternalName = "RotatesAt"; DisplayName = "RotatesAt"; Type = "DateTime" },
    @{ InternalName = "Notes"; DisplayName = "Notes"; Type = "Note" }
)

$existingFields = Get-PnPField -List $ListName
foreach ($f in $fields) {
    if (-not ($existingFields | Where-Object { $_.InternalName -eq $f.InternalName })) {
        Write-Info "Adding field $($f.DisplayName)"
        Add-PnPField -List $ListName -DisplayName $f.DisplayName -InternalName $f.InternalName -Type $f.Type -AddToDefaultView | Out-Null
        if ($f.Required) {
            Set-PnPField -List $ListName -Identity $f.InternalName -Values @{Required=$true} | Out-Null
        }
    } else {
        Write-Info "Field '$($f.DisplayName)' already exists."
    }
}

Write-Host "`n--- Tokens list structure verified successfully ---" -ForegroundColor Cyan
Disconnect-PnPOnline -ErrorAction SilentlyContinue
