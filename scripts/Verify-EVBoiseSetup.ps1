<#
.SYNOPSIS
    Verifies that EVBoise.com and www.EVBoise.com are configured correctly
    for Vercel hosting, SSL, and DNS resolution.
#>

# --- CONFIGURATION ---
$domain = "evboise.com"
$wwwDomain = "www.evboise.com"
$expectedARecords = @("76.76.21.21", "76.76.21.241") # typical Vercel A records
$expectedCNAMEPattern = "vercel-dns\.com$"
$expectedNameservers = @("ns1.vercel-dns.com", "elliott.ns.cloudflare.com", "galilea.ns.cloudflare.com")

# --- UTILITY FUNCTION ---
function Test-Port {
    param (
        [string]$TargetHost,
        [int]$Port = 443,
        [int]$Timeout = 2000
    )
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($TargetHost, $Port, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne($Timeout, $false)
        if ($success -and $tcp.Connected) {
            $tcp.Close()
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

Write-Host "🔍 Verifying $domain configuration..." -ForegroundColor Cyan

# --- A RECORD CHECK ---
$ARecord = (Resolve-DnsName -Name $domain -Type A -ErrorAction SilentlyContinue).IPAddress
if ($ARecord) {
    if ($ARecord -in $expectedARecords) {
        Write-Host "✅ A record points correctly to Vercel ($ARecord)"
    } else {
        Write-Host "❌ A record does NOT point to Vercel. Found: $ARecord" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  No A record found for $domain" -ForegroundColor Yellow
}

# --- CNAME CHECK (www) ---
$CNAME = (Resolve-DnsName -Name $wwwDomain -Type CNAME -ErrorAction SilentlyContinue).NameHost
if ($CNAME) {
    if ($CNAME -match $expectedCNAMEPattern) {
        Write-Host "✅ CNAME for www points correctly to Vercel ($CNAME)"
    } else {
        Write-Host "❌ CNAME for www is incorrect. Found: $CNAME" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  No CNAME record found for $wwwDomain" -ForegroundColor Yellow
}

# --- NAMESERVER CHECK ---
$nsRecords = (Resolve-DnsName -Name $domain -Type NS -ErrorAction SilentlyContinue).NameHost
if ($nsRecords) {
    Write-Host "📡 Current nameservers: $($nsRecords -join ', ')"
    $matches = $nsRecords | Where-Object { $_ -in $expectedNameservers }
    if ($matches.Count -gt 0) {
        Write-Host "✅ Expected nameservers are present"
    } else {
        Write-Host "❌ Nameservers do not match expected configuration" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  No NS records found for $domain" -ForegroundColor Yellow
}

# --- SSL PORT CHECK ---
if (Test-Port -TargetHost $domain -Port 443) {
    Write-Host "✅ SSL (HTTPS) port 443 is reachable"
} else {
    Write-Host "❌ SSL port 443 is NOT reachable" -ForegroundColor Red
}

# --- HTTP STATUS CHECK ---
try {
    $response = Invoke-WebRequest -Uri "https://$domain" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Website returned HTTP 200 OK"
    } else {
        Write-Host "⚠️  Website returned status $($response.StatusCode)"
    }
} catch {
    Write-Host "❌ Could not reach https://$domain — $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n✅ Verification complete."