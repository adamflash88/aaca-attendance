# Shared helpers for AACA provisioning scripts: sign-in (cached, DPAPI-encrypted), Web API calls,
# and OData payload serialization. Dot-source, then call Connect-Dataverse.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Public client used for sign-in (Microsoft Azure CLI). Override with -ClientId if a tenant blocks it.
$script:DvClientId = '04b07795-8ddb-461a-bbee-02f9e1bf7b46'
$script:DvTenantId = 'organizations'
$script:DvTokenExpires = $null
$script:DvSolutionManaged = $null

function New-Label([string] $text) {
    # Collections are List[object] so an empty or single-item list still serializes as a JSON array.
    $labels = [System.Collections.Generic.List[object]]::new()
    if ($text) { $labels.Add(@{ '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel'; Label = $text; LanguageCode = 1033 }) }
    @{ '@odata.type' = 'Microsoft.Dynamics.CRM.Label'; LocalizedLabels = $labels }
}

function ConvertTo-OrderedPayload($node) {
    # OData requires '@odata.type' to be the first property of each object; hashtables are
    # unordered, so rebuild every dictionary with it first.
    if ($node -is [System.Collections.IDictionary]) {
        $o = [ordered]@{}
        if ($node.Contains('@odata.type')) { $o['@odata.type'] = $node['@odata.type'] }
        foreach ($k in $node.Keys) { if ($k -ne '@odata.type') { $o[$k] = ConvertTo-OrderedPayload $node[$k] } }
        return $o
    }
    if ($node -is [System.Collections.IList]) {
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($i in $node) { $list.Add((ConvertTo-OrderedPayload $i)) }
        return , $list
    }
    return $node
}
function ConvertTo-Payload($body) { ConvertTo-Json -InputObject (ConvertTo-OrderedPayload $body) -Depth 30 -Compress }

#region Sign-in -------------------------------------------------------------------------
function Get-DvTokenCachePath { Join-Path $env:LOCALAPPDATA ("aaca-attendance\token-" + ([uri]$script:DvUrl).Host + '.dat') }

function Protect-DvText([string] $text) { if ($text) { ConvertTo-SecureString $text -AsPlainText -Force | ConvertFrom-SecureString } }
function Unprotect-DvText([string] $blob) { if ($blob) { [pscredential]::new('t', ($blob | ConvertTo-SecureString)).GetNetworkCredential().Password } }

function Save-DvToken($tok) {
    # Access and refresh tokens are DPAPI-encrypted for the current Windows user.
    $path = Get-DvTokenCachePath
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    $script:DvTokenExpires = (Get-Date).AddSeconds([int]$tok.expires_in - 300)
    $refresh = if ($tok.PSObject.Properties['refresh_token']) { $tok.refresh_token } else { $null }
    @{ expires = $script:DvTokenExpires.ToString('o'); token = (Protect-DvText $tok.access_token); refresh = (Protect-DvText $refresh) } |
        ConvertTo-Json | Set-Content $path
    return $tok.access_token
}

function Update-DvToken {
    # Exchange the cached refresh token for a new access token (no prompt). Returns $null if not possible.
    $path = Get-DvTokenCachePath
    if (-not (Test-Path $path)) { return $null }
    try {
        $c = Get-Content $path -Raw | ConvertFrom-Json
        $refresh = Unprotect-DvText $c.refresh
        if (-not $refresh) { return $null }
        $tok = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$script:DvTenantId/oauth2/v2.0/token" -Body @{
            grant_type = 'refresh_token'; client_id = $script:DvClientId; refresh_token = $refresh; scope = "$script:DvUrl/.default offline_access" }
        return Save-DvToken $tok
    } catch { return $null }
}

function Get-DvCachedToken {
    $path = Get-DvTokenCachePath
    if (-not (Test-Path $path)) { return $null }
    try {
        $c = Get-Content $path -Raw | ConvertFrom-Json
        $script:DvTokenExpires = [datetime]::Parse($c.expires)
        if ($script:DvTokenExpires -lt (Get-Date)) { return Update-DvToken }
        return Unprotect-DvText $c.token
    } catch { return $null }
}

function Get-DvDeviceCodeToken {
    $dc = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$script:DvTenantId/oauth2/v2.0/devicecode" `
        -Body @{ client_id = $script:DvClientId; scope = "$script:DvUrl/.default offline_access" }
    Write-Host $dc.message -ForegroundColor Yellow
    $deadline = (Get-Date).AddSeconds([int]$dc.expires_in)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds ([int]$dc.interval)
        try {
            $tok = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$script:DvTenantId/oauth2/v2.0/token" -Body @{
                grant_type = 'urn:ietf:params:oauth:grant-type:device_code'; client_id = $script:DvClientId; device_code = $dc.device_code }
            return Save-DvToken $tok
        } catch {
            $err = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).error
            if ($err -ne 'authorization_pending') { throw "Sign-in failed: $err" }
        }
    }
    throw 'Sign-in timed out.'
}

function Get-DvBrowserToken {
    # Authorization-code flow with PKCE and a localhost redirect.
    $bytes = [byte[]]::new(32); [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $b64url = { param($b) [Convert]::ToBase64String($b).TrimEnd('=').Replace('+', '-').Replace('/', '_') }
    $verifier = & $b64url $bytes
    $challenge = & $b64url ([Security.Cryptography.SHA256]::HashData([Text.Encoding]::ASCII.GetBytes($verifier)))
    $state = [guid]::NewGuid().ToString('N')
    $redirect = "http://localhost:$(Get-Random -Minimum 49152 -Maximum 65000)/"
    $listener = [Net.HttpListener]::new(); $listener.Prefixes.Add($redirect); $listener.Start()
    try {
        $scope = [uri]::EscapeDataString("$script:DvUrl/.default offline_access")
        Start-Process -WhatIf:$false ("https://login.microsoftonline.com/$script:DvTenantId/oauth2/v2.0/authorize?client_id=$script:DvClientId&response_type=code" +
                       "&redirect_uri=$([uri]::EscapeDataString($redirect))&scope=$scope&state=$state" +
                       "&code_challenge=$challenge&code_challenge_method=S256&prompt=select_account")
        Write-Host 'Opening your browser to sign in...' -ForegroundColor Yellow
        $task = $listener.GetContextAsync()
        if (-not $task.Wait([TimeSpan]::FromMinutes(5))) { throw 'Sign-in timed out after 5 minutes.' }
        $ctx = $task.Result
        $query = [Web.HttpUtility]::ParseQueryString($ctx.Request.Url.Query)
        $msg = if ($query['code']) { 'Signed in. You can close this tab.' } else { "Sign-in failed: $($query['error_description'])" }
        $out = [Text.Encoding]::UTF8.GetBytes("<html><body style='font-family:sans-serif'><h3>$([Net.WebUtility]::HtmlEncode($msg))</h3></body></html>")
        $ctx.Response.ContentType = 'text/html'; $ctx.Response.OutputStream.Write($out, 0, $out.Length); $ctx.Response.Close()
        if (-not $query['code']) { throw "Sign-in failed: $($query['error']) $($query['error_description'])" }
        if ($query['state'] -ne $state) { throw 'Sign-in failed: state mismatch.' }
    } finally { $listener.Stop() }
    $tok = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$script:DvTenantId/oauth2/v2.0/token" -Body @{
        grant_type = 'authorization_code'; client_id = $script:DvClientId; code = $query['code']; redirect_uri = $redirect; code_verifier = $verifier }
    return Save-DvToken $tok
}

function Connect-Dataverse {
    param([Parameter(Mandatory)] [string] $EnvironmentUrl, [string] $AccessToken, [switch] $UseDeviceCode, [string] $SolutionUniqueName)
    $script:DvUrl = $EnvironmentUrl.TrimEnd('/')
    $script:DvApi = "$script:DvUrl/api/data/v9.2"
    $script:DvSolution = $SolutionUniqueName
    $script:DvToken = if ($AccessToken) { $AccessToken } else { Get-DvCachedToken }
    if ($script:DvToken) { Write-Host 'Using cached sign-in.' }
    else { $script:DvToken = if ($UseDeviceCode) { Get-DvDeviceCodeToken } else { Get-DvBrowserToken } }
}
#endregion

function Invoke-Dv {
    # -InSolution adds a created metadata component to $script:DvSolution.
    param([string] $Method = 'Get', [string] $Path, $Body, [switch] $AllowNotFound, [switch] $InSolution, [hashtable] $ExtraHeaders)
    # Renew shortly before expiry so long runs (seed data) don't fail mid-way.
    if ($script:DvTokenExpires -and (Get-Date) -gt $script:DvTokenExpires) {
        $new = Update-DvToken
        if ($new) { $script:DvToken = $new } else { Write-Warning 'Sign-in expired and could not be renewed; re-run to sign in again.' }
    }
    $headers = @{
        Authorization      = "Bearer $script:DvToken"
        'OData-MaxVersion' = '4.0'
        'OData-Version'    = '4.0'
        Accept             = 'application/json'
    }
    if ($InSolution) { $headers['MSCRM.SolutionUniqueName'] = $script:DvSolution }
    if ($ExtraHeaders) { foreach ($k in $ExtraHeaders.Keys) { $headers[$k] = $ExtraHeaders[$k] } }
    $uri = if ($Path -match '^https?://') { $Path } else { "$script:DvApi/$Path" }
    $json = if ($null -ne $Body) { ConvertTo-Payload $Body } else { $null }
    for ($attempt = 1; ; $attempt++) {
        try {
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $json -ContentType 'application/json; charset=utf-8'
        } catch {
            $status = [int]($_.Exception.Response.StatusCode ?? 0)
            if ($AllowNotFound -and $status -eq 404) { return $null }
            if ($status -in 429, 503 -and $attempt -le 5) {
                $wait = [int]($_.Exception.Response.Headers.RetryAfter.Delta.TotalSeconds ?? (5 * $attempt))
                Write-Warning "Throttled ($status); retrying in $wait s"; Start-Sleep $wait; continue
            }
            $detail = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).error.message
            if ($detail -and $detail.Length -gt 600) { $detail = $detail.Substring(0, 600) + '...' }
            throw "$Method $uri failed ($status): $($detail ?? $_.ErrorDetails.Message)"
        }
    }
}

# Web API collection name for a table (e.g. aaca_campus -> aaca_campuses), read from metadata.
$script:DvEntitySets = @{}
function Get-DvEntitySet([string] $LogicalName) {
    if (-not $script:DvEntitySets.Contains($LogicalName)) {
        $script:DvEntitySets[$LogicalName] = (Invoke-Dv -Path "EntityDefinitions(LogicalName='$LogicalName')?`$select=EntitySetName").EntitySetName
    }
    $script:DvEntitySets[$LogicalName]
}

# Deletes many rows with OData $batch (up to 1000 requests per call). $Paths are relative, e.g. "aaca_attendances(<id>)".
function Remove-DvRows([string[]] $Paths, [int] $BatchSize = 1000) {
    $done = 0
    for ($i = 0; $i -lt $Paths.Count; $i += $BatchSize) {
        $chunk = $Paths[$i..([Math]::Min($i + $BatchSize, $Paths.Count) - 1)]
        $boundary = "batch_$([guid]::NewGuid().ToString('N'))"
        $sb = [System.Text.StringBuilder]::new()
        foreach ($p in $chunk) {
            [void]$sb.Append("--$boundary`r`nContent-Type: application/http`r`nContent-Transfer-Encoding: binary`r`n`r`nDELETE $script:DvApi/$p HTTP/1.1`r`n`r`n")
        }
        [void]$sb.Append("--$boundary--`r`n")
        if ($script:DvTokenExpires -and (Get-Date) -gt $script:DvTokenExpires) { $n = Update-DvToken; if ($n) { $script:DvToken = $n } }
        $resp = Invoke-WebRequest -Method Post -Uri "$script:DvApi/`$batch" -Body $sb.ToString() -ContentType "multipart/mixed;boundary=$boundary" -Headers @{
            Authorization = "Bearer $script:DvToken"; 'OData-MaxVersion' = '4.0'; 'OData-Version' = '4.0'; Accept = 'application/json'; Prefer = 'odata.continue-on-error' }
        $failed = ([regex]::Matches($resp.Content, 'HTTP/1\.1 (4|5)\d\d')).Count
        if ($failed) { Write-Warning "$failed of $($chunk.Count) deletes failed in this batch"; }
        $done += $chunk.Count - $failed
        Write-Host "    deleted $done / $($Paths.Count)"
    }
    return $done
}

# Deletes EVERY row of a table with a server-side BulkDelete job (much faster than per-row deletes) and waits.
function Clear-DvTable([string] $LogicalName, [int] $TimeoutMinutes = 30) {
    $body = @{
        QuerySet = @(@{
            '@odata.type' = 'Microsoft.Dynamics.CRM.QueryExpression'
            EntityName    = $LogicalName
            ColumnSet     = @{ AllColumns = $false; Columns = @() }
            Criteria      = @{ FilterOperator = 'And'; Conditions = @() }
        })
        JobName               = "AACA reset $LogicalName $(Get-Date -Format s)"
        SendEmailNotification = $false
        ToRecipients          = @()
        CCRecipients          = @()
        RecurrencePattern     = ''
        StartDateTime         = (Get-Date).ToUniversalTime().ToString('o')
    }
    $job = Invoke-Dv -Method Post -Path 'BulkDelete' -Body $body
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    do {
        Start-Sleep -Seconds 5
        $op = Invoke-Dv -Path "asyncoperations($($job.JobId))?`$select=statecode,statuscode,message"
    } while ($op.statecode -ne 3 -and (Get-Date) -lt $deadline)
    if ($op.statecode -ne 3) { throw "Bulk delete of $LogicalName did not finish within $TimeoutMinutes minutes (job $($job.JobId))." }
    if ($op.statuscode -ne 30) { throw "Bulk delete of $LogicalName failed (status $($op.statuscode)): $($op.message)" }
}

# Returns every row of a query, following @odata.nextLink paging.
function Get-DvAll([string] $Path) {
    $rows = [System.Collections.Generic.List[object]]::new()
    $next = $Path
    while ($next) {
        $page = Invoke-Dv -Path $next -ExtraHeaders @{ Prefer = 'odata.maxpagesize=5000' }
        foreach ($r in $page.value) { $rows.Add($r) }
        $next = if ($page.PSObject.Properties['@odata.nextLink']) { $page.'@odata.nextLink' } else { $null }
    }
    return , $rows
}

# Creates a row and returns it (Prefer: return=representation), so callers get the new id.
function New-DvRow([string] $EntitySet, [hashtable] $Body) {
    Invoke-Dv -Method Post -Path $EntitySet -Body $Body -ExtraHeaders @{ Prefer = 'return=representation' }
}

function Add-DvSolutionComponent([guid] $ComponentId, [int] $ComponentType) {
    # Test/Production hold the solution as managed, which can't take new components: leave them unmanaged there.
    if ($null -eq $script:DvSolutionManaged) {
        $s = (Invoke-Dv -Path "solutions?`$select=ismanaged&`$filter=uniquename eq '$script:DvSolution'").value | Select-Object -First 1
        $script:DvSolutionManaged = [bool]($s -and $s.ismanaged)
    }
    if ($script:DvSolutionManaged) { return }
    Invoke-Dv -Method Post -Path 'AddSolutionComponent' -Body @{
        ComponentId = $ComponentId; ComponentType = $ComponentType; SolutionUniqueName = $script:DvSolution
        AddRequiredComponents = $false; DoNotIncludeSubcomponents = $false
    } | Out-Null
}
