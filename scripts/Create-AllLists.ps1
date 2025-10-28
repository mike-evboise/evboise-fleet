<#!
.SYNOPSIS
    EVBoise SharePoint Site Bootstrap — creates/validates core lists with comprehensive schemas.

.DESCRIPTION
    Reads SharePoint connection settings from a local .env file and connects using PnP.PowerShell.
    For EACH list, the script PAUSES and asks for confirmation before creating it if missing.
    After creation (or if already exists), it ensures all required columns exist (idempotent).

    Lists provisioned (comprehensive fields):
      1) Vehicles
      2) Customers
      3) Rentals (Lookups -> Vehicles, Customers)
      4) FleetMaintenance (Lookup -> Vehicles)
      5) Tokens

    .env file must define:
      EVBOISE_SITE_URL=https://evboise.sharepoint.com/sites/EVBoiseFleet
      EVBOISE_TENANT_ID=<tenant-guid>
      EVBOISE_CLIENT_ID=<app-client-id>

.REQUIREMENTS
    - PowerShell 7+
    - Module: PnP.PowerShell  (# auto-install toggle below)

.USAGE
    pwsh ./scripts/Create-AllLists.ps1

.NOTES
    Author: Mike Carter (EVBoise)
    Date: 2025-10-27
    Safety: This script only creates list structure; it does not import data.
!#>

# ====== CONFIG ======
$EnvPath  = "C:\Users\mnc35\OneDrive\Documents\Python\.env"   # change if needed
$AutoInstallPnP = $true   # set $false to skip auto-install

# ====== Helpers ======
function Write-Info($m){ Write-Host "[INFO]  $m" }
function Write-Warn($m){ Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Ensure PnP module
if ($AutoInstallPnP -and -not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
  Write-Warn "PnP.PowerShell not found. Installing for CurrentUser..."
  try { Install-Module PnP.PowerShell -Scope CurrentUser -AllowClobber -Force -ErrorAction Stop }
  catch { Write-Err "Failed to install PnP.PowerShell: $($_.Exception.Message)"; throw }
}
Import-Module PnP.PowerShell -ErrorAction Stop

# ====== Load .env ======
if (!(Test-Path -LiteralPath $EnvPath)) { throw ".env file not found at $EnvPath" }
Write-Info "Loading environment variables from $EnvPath"
$envVars = @{}
Get-Content -LiteralPath $EnvPath | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#')) { return }
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
Write-Info "Connecting to SharePoint: $SiteUrl"
Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $TenantId -Interactive -ErrorAction Stop
Write-Info "Connected."

# ====== Field ensure helpers ======
function Ensure-Field {
  param(
    [Parameter(Mandatory)] [string] $ListName,
    [Parameter(Mandatory)] [string] $InternalName,
    [Parameter(Mandatory)] [string] $DisplayName,
    [Parameter(Mandatory)] [ValidateSet('Text','Note','Number','Currency','DateTime','Choice','Lookup','Boolean','Url')]
    [string] $Type,
    [string[]] $Choices,
    [bool] $Required = $false,
    [string] $LookupList,
    [string] $LookupField = 'Title'
  )
  $existing = Get-PnPField -List $ListName -ErrorAction SilentlyContinue | Where-Object { $_.InternalName -eq $InternalName }
  if ($existing) {
    Write-Info "Field exists: $ListName::$DisplayName ($InternalName)"
    return
  }
  Write-Info "Adding field: $ListName::$DisplayName ($InternalName) as $Type"
  switch ($Type) {
    'Choice'   { Add-PnPField -List $ListName -DisplayName $DisplayName -InternalName $InternalName -Type Choice -AddToDefaultView -Choices $Choices | Out-Null }
    'Lookup'   { Add-PnPField -List $ListName -DisplayName $DisplayName -InternalName $InternalName -Type Lookup -AddToDefaultView -LookupList $LookupList -LookupField $LookupField | Out-Null }
    'Currency' { Add-PnPField -List $ListName -DisplayName $DisplayName -InternalName $InternalName -Type Currency -AddToDefaultView | Out-Null }
    default    { Add-PnPField -List $ListName -DisplayName $DisplayName -InternalName $InternalName -Type $Type -AddToDefaultView | Out-Null }
  }
  if ($Required) { Set-PnPField -List $ListName -Identity $InternalName -Values @{ Required = $true } | Out-Null }
}

function Ensure-List {
  param(
    [Parameter(Mandatory)] [string] $ListName,
    [string] $Description = ''
  )
  $list = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
  if (-not $list) {
    Write-Warn "List '$ListName' does not exist. $Description"
    $resp = Read-Host "Create list '$ListName' now? (Y/N)"
    if ($resp -notin @('Y','y')) { Write-Warn "Skipped '$ListName' per user."; return $null }
    Write-Info "Creating list '$ListName'..."
    $list = New-PnPList -Title $ListName -Template GenericList -OnQuickLaunch -EnableVersioning -ErrorAction Stop
    Write-Info "Created list '$ListName'"
  } else {
    Write-Info "List exists: '$ListName'"
  }
  return $list
}

# ====== 1) Vehicles ======
$vehiclesDesc = 'Fleet inventory: identity, specs, status, compliance, lifecycle.'
$vehicles = Ensure-List -ListName 'Vehicles' -Description $vehiclesDesc
if ($vehicles) {
  Ensure-Field -ListName 'Vehicles' -InternalName 'Title'            -DisplayName 'Vehicle Name' -Type Text -Required:$true
  Ensure-Field -ListName 'Vehicles' -InternalName 'VIN'              -DisplayName 'VIN'          -Type Text -Required:$true
  Ensure-Field -ListName 'Vehicles' -InternalName 'Plate'            -DisplayName 'Plate'        -Type Text
  Ensure-Field -ListName 'Vehicles' -InternalName 'Year'             -DisplayName 'Year'         -Type Number
  Ensure-Field -ListName 'Vehicles' -InternalName 'Make'             -DisplayName 'Make'         -Type Text
  Ensure-Field -ListName 'Vehicles' -InternalName 'Model'            -DisplayName 'Model'        -Type Text
  Ensure-Field -ListName 'Vehicles' -InternalName 'Trim'             -DisplayName 'Trim'         -Type Text
  Ensure-Field -ListName 'Vehicles' -InternalName 'Color'            -DisplayName 'Color'        -Type Text
  Ensure-Field -ListName 'Vehicles' -InternalName 'Mileage'          -DisplayName 'Mileage'      -Type Number
  Ensure-Field -ListName 'Vehicles' -InternalName 'BatteryKWh'       -DisplayName 'Battery (kWh)'-Type Number
  Ensure-Field -ListName 'Vehicles' -InternalName 'PurchaseDate'     -DisplayName 'Purchase Date'-Type DateTime
  Ensure-Field -ListName 'Vehicles' -InternalName 'InServiceDate'    -DisplayName 'In Service'   -Type DateTime
  Ensure-Field -ListName 'Vehicles' -InternalName 'InsurancePolicy'  -DisplayName 'Insurance Policy' -Type Text
  Ensure-Field -ListName 'Vehicles' -InternalName 'RegistrationExp'  -DisplayName 'Registration Expiry' -Type DateTime
  Ensure-Field -ListName 'Vehicles' -InternalName 'Location'         -DisplayName 'Current Location' -Type Text
  Ensure-Field -ListName 'Vehicles' -InternalName 'Status'           -DisplayName 'Status'       -Type Choice -Choices @('Active','InMaintenance','Retired','Reserved','OutOfService')
  Ensure-Field -ListName 'Vehicles' -InternalName 'Notes'            -DisplayName 'Notes'        -Type Note
}

# ====== 2) Customers ======
$customersDesc = 'Renter/contact records with licensing & billing metadata.'
$customers = Ensure-List -ListName 'Customers' -Description $customersDesc
if ($customers) {
  Ensure-Field -ListName 'Customers' -InternalName 'Title'           -DisplayName 'Full Name'    -Type Text -Required:$true
  Ensure-Field -ListName 'Customers' -InternalName 'Email'           -DisplayName 'Email'        -Type Text -Required:$true
  Ensure-Field -ListName 'Customers' -InternalName 'Phone'           -DisplayName 'Phone'        -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'DLNumber'        -DisplayName 'Driver License #' -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'DLState'         -DisplayName 'License State' -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'DOB'             -DisplayName 'Date of Birth' -Type DateTime
  Ensure-Field -ListName 'Customers' -InternalName 'Address1'        -DisplayName 'Address 1'    -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'Address2'        -DisplayName 'Address 2'    -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'City'            -DisplayName 'City'         -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'State'           -DisplayName 'State/Prov'   -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'PostalCode'      -DisplayName 'ZIP/Postal'   -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'Country'         -DisplayName 'Country'      -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'PreferredPay'    -DisplayName 'Preferred Payment' -Type Choice -Choices @('Card','ACH','Cash','Other')
  Ensure-Field -ListName 'Customers' -InternalName 'StripeCustomerId'-DisplayName 'Stripe Customer Id' -Type Text
  Ensure-Field -ListName 'Customers' -InternalName 'Notes'           -DisplayName 'Notes'        -Type Note
}

# ====== 3) Rentals ======
$rentalsDesc = 'Bookings/contracts with pricing, mileage, and channel meta.'
$rentals = Ensure-List -ListName 'Rentals' -Description $rentalsDesc
if ($rentals) {
  # Lookups need the target lists to exist. Use list titles as -LookupList.
  Ensure-Field -ListName 'Rentals' -InternalName 'Title'            -DisplayName 'Rental Name' -Type Text -Required:$true
  Ensure-Field -ListName 'Rentals' -InternalName 'VehicleLookup'    -DisplayName 'Vehicle'     -Type Lookup -LookupList 'Vehicles' -LookupField 'Title'
  Ensure-Field -ListName 'Rentals' -InternalName 'CustomerLookup'   -DisplayName 'Customer'    -Type Lookup -LookupList 'Customers' -LookupField 'Title'
  Ensure-Field -ListName 'Rentals' -InternalName 'StartDate'        -DisplayName 'Start Date'  -Type DateTime -Required:$true
  Ensure-Field -ListName 'Rentals' -InternalName 'EndDate'          -DisplayName 'End Date'    -Type DateTime
  Ensure-Field -ListName 'Rentals' -InternalName 'Channel'          -DisplayName 'Channel'     -Type Choice -Choices @('Direct','Turo','Other')
  Ensure-Field -ListName 'Rentals' -InternalName 'Status'           -DisplayName 'Status'      -Type Choice -Choices @('Reserved','Active','Completed','Canceled','NoShow')
  Ensure-Field -ListName 'Rentals' -InternalName 'DailyRate'        -DisplayName 'Daily Rate'  -Type Currency
  Ensure-Field -ListName 'Rentals' -InternalName 'EstimatedTotal'   -DisplayName 'Estimated Total' -Type Currency
  Ensure-Field -ListName 'Rentals' -InternalName 'ActualTotal'      -DisplayName 'Actual Total' -Type Currency
  Ensure-Field -ListName 'Rentals' -InternalName 'PickupLocation'   -DisplayName 'Pickup Location' -Type Text
  Ensure-Field -ListName 'Rentals' -InternalName 'DropoffLocation'  -DisplayName 'Drop-off Location' -Type Text
  Ensure-Field -ListName 'Rentals' -InternalName 'OdometerStart'    -DisplayName 'Odometer Start' -Type Number
  Ensure-Field -ListName 'Rentals' -InternalName 'OdometerEnd'      -DisplayName 'Odometer End' -Type Number
  Ensure-Field -ListName 'Rentals' -InternalName 'AgreementUrl'     -DisplayName 'Agreement URL' -Type Url
  Ensure-Field -ListName 'Rentals' -InternalName 'Notes'            -DisplayName 'Notes'       -Type Note
}

# ====== 4) FleetMaintenance ======
$fmDesc = 'Work orders, service, parts, and costs tied to vehicles.'
$fleetMaint = Ensure-List -ListName 'FleetMaintenance' -Description $fmDesc
if ($fleetMaint) {
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'Title'         -DisplayName 'Work Order'    -Type Text -Required:$true
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'VehicleLookup' -DisplayName 'Vehicle'       -Type Lookup -LookupList 'Vehicles' -LookupField 'Title'
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'ServiceDate'   -DisplayName 'Service Date'  -Type DateTime -Required:$true
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'Odometer'      -DisplayName 'Odometer'      -Type Number
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'Vendor'        -DisplayName 'Vendor'        -Type Text
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'ServiceType'   -DisplayName 'Service Type'  -Type Choice -Choices @('Tires','Brakes','Battery','Body','Inspection','Software','Other')
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'Cost'          -DisplayName 'Cost'          -Type Currency
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'InvoiceNumber' -DisplayName 'Invoice #'     -Type Text
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'NextDueDate'   -DisplayName 'Next Due Date' -Type DateTime
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'Warranty'      -DisplayName 'Warranty'      -Type Text
  Ensure-Field -ListName 'FleetMaintenance' -InternalName 'Notes'         -DisplayName 'Notes'         -Type Note
}

# ====== 5) Tokens (metadata only; do not store real secrets) ======
$tokensDesc = 'Integration token metadata (no raw secrets).'
$tokens = Ensure-List -ListName 'Tokens' -Description $tokensDesc
if ($tokens) {
  Ensure-Field -ListName 'Tokens' -InternalName 'Title'        -DisplayName 'Name'       -Type Text -Required:$true
  Ensure-Field -ListName 'Tokens' -InternalName 'SecretValue'  -DisplayName 'Secret'     -Type Note
  Ensure-Field -ListName 'Tokens' -InternalName 'Scope'        -DisplayName 'Scope'      -Type Text
  Ensure-Field -ListName 'Tokens' -InternalName 'ExpiresAt'    -DisplayName 'ExpiresAt'  -Type DateTime
  Ensure-Field -ListName 'Tokens' -InternalName 'RotatesAt'    -DisplayName 'RotatesAt'  -Type DateTime
  Ensure-Field -ListName 'Tokens' -InternalName 'Notes'        -DisplayName 'Notes'      -Type Note
}

Write-Host "`n--- All requested lists processed. ---" -ForegroundColor Cyan
Disconnect-PnPOnline -ErrorAction SilentlyContinue
