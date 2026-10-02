<#
.SYNOPSIS
    Creates the AACA Attendance Dataverse schema (publisher, solution, tables, columns,
    lookups, alternate keys) from schema/tables.json. Safe to re-run: existing items are skipped.

.DESCRIPTION
    Uses the Dataverse Web API. Signs in through your default browser (or a device code with
    -UseDeviceCode), or takes a token you already have via -AccessToken. The token is cached
    for its lifetime (~1 hour), encrypted for the current Windows user (DPAPI), so a re-run
    doesn't prompt again.

    Every created component is added to the solution (MSCRM.SolutionUniqueName header).
    Lookups are created with cascade NoCascade for Assign/Share/Reparent so reassigning a
    student to a new teacher never moves historical enrollments or attendance. Deleting a
    referenced record is Restricted (history can't be orphaned) except for user lookups.

.PARAMETER EnvironmentUrl
    Dataverse environment URL, e.g. https://org12345.crm.dynamics.com

.PARAMETER PlanOnly
    Validate schema/tables.json, build and check every request payload, and print the plan.
    No sign-in, no changes.

.EXAMPLE
    ./Deploy-Schema.ps1 -PlanOnly
    ./Deploy-Schema.ps1 -EnvironmentUrl https://org12345.crm.dynamics.com
#>
[CmdletBinding()]
param(
    [string] $EnvironmentUrl,
    [string] $SchemaPath = (Join-Path $PSScriptRoot '..\schema\tables.json'),
    [string] $AccessToken,
    # Public client used for sign-in (Microsoft Azure CLI). Override if your tenant blocks it.
    [string] $ClientId = '04b07795-8ddb-461a-bbee-02f9e1bf7b46',
    [string] $TenantId = 'organizations',
    [switch] $EnableOrgAuditing,
    # Use the device-code prompt instead of a browser pop-up (for machines without a browser).
    [switch] $UseDeviceCode,
    [switch] $PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$schema = Get-Content $SchemaPath -Raw | ConvertFrom-Json
# Built-in tables a lookup may target besides our own (contact = family portal guardians).
$systemTargets = 'systemuser', 'contact'
function Get-Prop($obj, [string] $name, $default = $null) {
    if ($obj.PSObject.Properties[$name]) { $obj.$name } else { $default }
}

#region Validation ----------------------------------------------------------------------
function Test-Schema {
    $errors = [System.Collections.Generic.List[string]]::new()
    $prefix = "$($schema.publisher.prefix)_"
    $tableNames = @($schema.tables.logicalName)
    $validTypes = 'text', 'bool', 'date', 'datetime', 'choice', 'int', 'memo', 'autonumber'
    $minOpt = [int]$schema.publisher.optionValuePrefix * 10000

    foreach ($t in $schema.tables) {
        if (-not $t.logicalName.StartsWith($prefix)) { $errors.Add("Table $($t.logicalName): missing prefix $prefix") }
        $colNames = @($t.primaryName.logicalName) + @($t.columns.logicalName) +
                    @($schema.lookups | Where-Object table -eq $t.logicalName | ForEach-Object logicalName)
        $dupes = $colNames | Group-Object | Where-Object Count -gt 1
        foreach ($d in $dupes) { $errors.Add("Table $($t.logicalName): duplicate column $($d.Name)") }
        foreach ($c in $t.columns) {
            if ($c.type -notin $validTypes) { $errors.Add("$($t.logicalName).$($c.logicalName): unknown type $($c.type)") }
            if (-not $c.logicalName.StartsWith($prefix)) { $errors.Add("$($t.logicalName).$($c.logicalName): missing prefix") }
            if ($c.type -eq 'choice') {
                foreach ($o in $c.options) {
                    if ([int]$o[0] -lt $minOpt -or [int]$o[0] -gt $minOpt + 9999) { $errors.Add("$($t.logicalName).$($c.logicalName): option $($o[0]) outside publisher range") }
                }
                if ($c.PSObject.Properties['default'] -and $c.default -notin @($c.options | ForEach-Object { $_[0] })) {
                    $errors.Add("$($t.logicalName).$($c.logicalName): default $($c.default) is not an option")
                }
            }
        }
        foreach ($k in @($t.PSObject.Properties['keys'] ? $t.keys : @())) {
            foreach ($kc in $k.columns) { if ($kc -notin $colNames) { $errors.Add("Key $($k.logicalName): column $kc not on $($t.logicalName)") } }
        }
    }
    foreach ($l in $schema.lookups) {
        if ($l.table -notin $tableNames) { $errors.Add("Lookup $($l.logicalName): unknown table $($l.table)") }
        if ($l.target -notin $systemTargets -and $l.target -notin $tableNames) { $errors.Add("Lookup $($l.table).$($l.logicalName): unknown target $($l.target)") }
        if ((Get-Prop $l 'onDelete' 'Restrict') -notin 'Restrict', 'RemoveLink', 'Cascade') { $errors.Add("Lookup $($l.table).$($l.logicalName): unknown onDelete $($l.onDelete)") }
    }
    return $errors
}

$validationErrors = @(Test-Schema)
if ($validationErrors.Count) {
    $validationErrors | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Schema validation failed with $($validationErrors.Count) error(s)."
}
Write-Host "Schema OK: $($schema.tables.Count) tables, $(@($schema.tables.columns).Count) columns, $($schema.lookups.Count) lookups, $(@($schema.tables | Where-Object { $_.PSObject.Properties['keys'] } | ForEach-Object keys).Count) keys." -ForegroundColor Green
#endregion

#region Payload builders ----------------------------------------------------------------
# PowerShell unrolls arrays returned from if/else and functions, so collections are built as
# List[object] (always serialized as a JSON array, even when empty or single-item).
function New-Label([string] $text) {
    $labels = [System.Collections.Generic.List[object]]::new()
    if ($text) { $labels.Add(@{ '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel'; Label = $text; LanguageCode = 1033 }) }
    @{ '@odata.type' = 'Microsoft.Dynamics.CRM.Label'; LocalizedLabels = $labels }
}
function New-Required([bool] $required) {
    @{ Value = $(if ($required) { 'ApplicationRequired' } else { 'None' }); CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyrequirementlevelsettings' }
}
function New-AuditSetting { @{ Value = $true; CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyauditsettings' } }

function New-AttributeBody($c) {
    $base = @{
        SchemaName     = $c.logicalName
        DisplayName    = New-Label $c.displayName
        Description    = New-Label (Get-Prop $c 'description' '')
        RequiredLevel  = New-Required ([bool](Get-Prop $c 'required' $false))
        IsSecured      = [bool](Get-Prop $c 'secured' $false)
        IsAuditEnabled = New-AuditSetting
    }
    switch ($c.type) {
        'text' {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
            $base.MaxLength = [int]$c.maxLength; $base.FormatName = @{ Value = 'Text' }
        }
        'autonumber' {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
            $base.MaxLength = [int]$c.maxLength; $base.FormatName = @{ Value = 'Text' }; $base.AutoNumberFormat = $c.format
        }
        'memo' {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'
            $base.MaxLength = [int]$c.maxLength; $base.Format = 'TextArea'
        }
        'int' {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.IntegerAttributeMetadata'
            $base.MinValue = [int](Get-Prop $c 'min' -2147483648); $base.MaxValue = [int](Get-Prop $c 'max' 2147483647); $base.Format = 'None'
        }
        'bool' {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.BooleanAttributeMetadata'
            $base.DefaultValue = [bool](Get-Prop $c 'default' $false)
            $base.OptionSet = @{
                '@odata.type' = 'Microsoft.Dynamics.CRM.BooleanOptionSetMetadata'
                TrueOption  = @{ Value = 1; Label = New-Label 'Yes' }
                FalseOption = @{ Value = 0; Label = New-Label 'No' }
            }
        }
        'date' {
            # Date only + DateOnly behaviour: no time-zone shifting of calendar dates.
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
            $base.Format = 'DateOnly'; $base.DateTimeBehavior = @{ Value = 'DateOnly' }
        }
        'datetime' {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
            $base.Format = 'DateAndTime'; $base.DateTimeBehavior = @{ Value = 'UserLocal' }
        }
        'choice' {
            $options = [System.Collections.Generic.List[object]]::new()
            foreach ($o in $c.options) { $options.Add(@{ Value = [int]$o[0]; Label = New-Label ([string]$o[1]) }) }
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.PicklistAttributeMetadata'
            $base.DefaultFormValue = [int](Get-Prop $c 'default' -1)
            $base.OptionSet = @{
                '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
                IsGlobal = $false; OptionSetType = 'Picklist'; Options = $options
            }
        }
    }
    return $base
}

function New-TableBody($t) {
    $primary = New-AttributeBody ([pscustomobject]@{
        logicalName = $t.primaryName.logicalName; type = 'text'; displayName = $t.primaryName.displayName
        maxLength = $t.primaryName.maxLength; required = $true; description = (Get-Prop $t.primaryName 'description' '') })
    $primary.IsPrimaryName = $true
    $attributes = [System.Collections.Generic.List[object]]::new(); $attributes.Add($primary)
    @{
        '@odata.type'         = 'Microsoft.Dynamics.CRM.EntityMetadata'
        SchemaName            = $t.logicalName
        DisplayName           = New-Label $t.displayName
        DisplayCollectionName = New-Label $t.pluralName
        Description           = New-Label $t.description
        OwnershipType         = 'UserOwned'
        HasActivities         = $false
        HasNotes              = $false
        IsActivity            = $false
        IsAuditEnabled        = New-AuditSetting
        Attributes            = $attributes
    }
}

function New-LookupBody($l) {
    $onDelete = Get-Prop $l 'onDelete' $(if ($l.target -eq 'systemuser') { 'RemoveLink' } else { 'Restrict' })
    # Dataverse requires Merge = Cascade on relationships to contact (contacts can be merged).
    $merge = if ($l.target -eq 'contact') { 'Cascade' } else { 'NoCascade' }
    @{
        '@odata.type'        = 'Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata'
        SchemaName           = "$($l.table)_$($l.logicalName)"
        ReferencedEntity     = $l.target
        ReferencedAttribute  = "$($l.target)id"
        ReferencingEntity    = $l.table
        CascadeConfiguration = @{ Assign = 'NoCascade'; Share = 'NoCascade'; Unshare = 'NoCascade'; Reparent = 'NoCascade'
                                  Merge = $merge; RollupView = 'NoCascade'; Delete = $onDelete }
        Lookup               = @{
            '@odata.type'  = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
            SchemaName     = $l.logicalName
            DisplayName    = New-Label $l.displayName
            Description    = New-Label (Get-Prop $l 'description' '')
            RequiredLevel  = New-Required ([bool](Get-Prop $l 'required' $false))
            IsSecured      = [bool](Get-Prop $l 'secured' $false)
            IsAuditEnabled = New-AuditSetting
        }
    }
}

function New-KeyBody($k) {
    $cols = [System.Collections.Generic.List[string]]::new(); foreach ($kc in $k.columns) { $cols.Add($kc) }
    @{ SchemaName = $k.logicalName; DisplayName = New-Label $k.displayName; KeyAttributes = $cols }
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
#endregion

#region Plan / payload self-test --------------------------------------------------------
if ($PlanOnly) {
    # Build every payload offline and reject nulls or collections serialized as objects.
    $payloads = @()
    foreach ($t in $schema.tables) {
        $payloads += [pscustomobject]@{ Name = "table $($t.logicalName)"; Json = ConvertTo-Payload (New-TableBody $t) }
        foreach ($c in $t.columns) { $payloads += [pscustomobject]@{ Name = "column $($t.logicalName).$($c.logicalName)"; Json = ConvertTo-Payload (New-AttributeBody $c) } }
        foreach ($k in @(Get-Prop $t 'keys' @())) { $payloads += [pscustomobject]@{ Name = "key $($k.logicalName)"; Json = ConvertTo-Payload (New-KeyBody $k) } }
    }
    foreach ($l in $schema.lookups) { $payloads += [pscustomobject]@{ Name = "lookup $($l.table).$($l.logicalName)"; Json = ConvertTo-Payload (New-LookupBody $l) } }
    $bad = $payloads | Where-Object { $_.Json -match ':null' -or $_.Json -match '"(LocalizedLabels|Options|Attributes|KeyAttributes)":\{' -or
                                      $_.Json -match '[^{]"@odata\.type"' }   # '@odata.type' must open its object
    if ($bad) { $bad | ForEach-Object { Write-Error "Bad payload for $($_.Name): $($_.Json)" -ErrorAction Continue }; throw 'Payload self-test failed.' }
    Write-Host "Payload self-test OK: $($payloads.Count) request bodies built with no nulls." -ForegroundColor Green

    foreach ($t in $schema.tables) {
        Write-Host "`n$($t.displayName) [$($t.logicalName)]" -ForegroundColor Cyan
        Write-Host ("  {0,-28} text (primary name)" -f $t.primaryName.logicalName)
        foreach ($c in $t.columns) {
            $flags = @(if (Get-Prop $c 'required' $false) { 'required' }
                       if (Get-Prop $c 'secured' $false) { 'SECURED' })
            Write-Host ("  {0,-28} {1} {2}" -f $c.logicalName, $c.type, ($flags -join ' '))
        }
        foreach ($l in $schema.lookups | Where-Object table -eq $t.logicalName) {
            Write-Host ("  {0,-28} lookup -> {1} {2}" -f $l.logicalName, $l.target, $(if (Get-Prop $l 'secured' $false) { 'SECURED' }))
        }
        foreach ($k in @(Get-Prop $t 'keys' @())) { Write-Host "  KEY $($k.logicalName): $($k.columns -join ' + ')" -ForegroundColor Yellow }
    }
    return
}
if (-not $EnvironmentUrl) { throw '-EnvironmentUrl is required unless -PlanOnly is used.' }
#endregion

#region Auth ----------------------------------------------------------------------------
$EnvironmentUrl = $EnvironmentUrl.TrimEnd('/')
$api = "$EnvironmentUrl/api/data/v9.2"
$tokenCache = Join-Path $env:LOCALAPPDATA ("aaca-attendance\token-" + ([uri]$EnvironmentUrl).Host + '.dat')

function Save-Token($tok) {
    # DPAPI-encrypted for the current Windows user; expires with the token.
    New-Item -ItemType Directory -Force (Split-Path $tokenCache) | Out-Null
    $expires = (Get-Date).AddSeconds([int]$tok.expires_in - 300).ToString('o')
    $secure = ConvertTo-SecureString $tok.access_token -AsPlainText -Force | ConvertFrom-SecureString
    @{ expires = $expires; token = $secure } | ConvertTo-Json | Set-Content $tokenCache
    return $tok.access_token
}
function Get-CachedToken {
    if (-not (Test-Path $tokenCache)) { return $null }
    try {
        $c = Get-Content $tokenCache -Raw | ConvertFrom-Json
        if ([datetime]::Parse($c.expires) -lt (Get-Date)) { return $null }
        return [pscredential]::new('t', ($c.token | ConvertTo-SecureString)).GetNetworkCredential().Password
    } catch { return $null }
}

function Get-DeviceCodeToken {
    $scope = "$EnvironmentUrl/.default offline_access"
    $dc = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode" `
        -Body @{ client_id = $ClientId; scope = $scope }
    Write-Host $dc.message -ForegroundColor Yellow
    $deadline = (Get-Date).AddSeconds([int]$dc.expires_in)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds ([int]$dc.interval)
        try {
            $tok = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body @{
                grant_type = 'urn:ietf:params:oauth:grant-type:device_code'; client_id = $ClientId; device_code = $dc.device_code }
            return Save-Token $tok
        } catch {
            $err = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).error
            if ($err -ne 'authorization_pending') { throw "Sign-in failed: $err" }
        }
    }
    throw 'Sign-in timed out.'
}

function Get-BrowserToken {
    # Authorization-code flow with PKCE and a localhost redirect: opens the default browser,
    # where an existing Microsoft 365 session usually signs in with one click.
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = [byte[]]::new(32); $rng.GetBytes($bytes)
    $b64url = { param($b) [Convert]::ToBase64String($b).TrimEnd('=').Replace('+', '-').Replace('/', '_') }
    $verifier = & $b64url $bytes
    $challenge = & $b64url ([Security.Cryptography.SHA256]::HashData([Text.Encoding]::ASCII.GetBytes($verifier)))
    $state = [guid]::NewGuid().ToString('N')

    $port = Get-Random -Minimum 49152 -Maximum 65000
    $redirect = "http://localhost:$port/"
    $listener = [Net.HttpListener]::new(); $listener.Prefixes.Add($redirect); $listener.Start()
    try {
        $scope = [uri]::EscapeDataString("$EnvironmentUrl/.default offline_access")
        $authUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize?client_id=$ClientId&response_type=code" +
                   "&redirect_uri=$([uri]::EscapeDataString($redirect))&scope=$scope&state=$state" +
                   "&code_challenge=$challenge&code_challenge_method=S256&prompt=select_account"
        Write-Host 'Opening your browser to sign in...' -ForegroundColor Yellow
        Start-Process $authUrl
        $task = $listener.GetContextAsync()
        if (-not $task.Wait([TimeSpan]::FromMinutes(5))) { throw 'Sign-in timed out after 5 minutes.' }
        $ctx = $task.Result
        $query = [Web.HttpUtility]::ParseQueryString($ctx.Request.Url.Query)
        $msg = if ($query['code']) { 'Signed in. You can close this tab and return to the terminal.' } else { "Sign-in failed: $($query['error_description'])" }
        $out = [Text.Encoding]::UTF8.GetBytes("<html><body style='font-family:sans-serif'><h3>$([Net.WebUtility]::HtmlEncode($msg))</h3></body></html>")
        $ctx.Response.ContentType = 'text/html'; $ctx.Response.OutputStream.Write($out, 0, $out.Length); $ctx.Response.Close()
        if (-not $query['code']) { throw "Sign-in failed: $($query['error']) $($query['error_description'])" }
        if ($query['state'] -ne $state) { throw 'Sign-in failed: state mismatch.' }
    } finally { $listener.Stop() }

    $tok = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body @{
        grant_type = 'authorization_code'; client_id = $ClientId; code = $query['code']
        redirect_uri = $redirect; code_verifier = $verifier }
    return Save-Token $tok
}

if (-not $AccessToken) { $AccessToken = Get-CachedToken }
if ($AccessToken) { Write-Host 'Using cached sign-in.' }
else { $AccessToken = if ($UseDeviceCode) { Get-DeviceCodeToken } else { Get-BrowserToken } }
#endregion

#region HTTP ----------------------------------------------------------------------------
function Invoke-Dv {
    # -InSolution adds the created component to the solution; only valid for metadata
    # creates, and only once the solution exists.
    param([string] $Method = 'Get', [string] $Path, $Body, [switch] $AllowNotFound, [switch] $InSolution)
    $headers = @{
        Authorization      = "Bearer $AccessToken"
        'OData-MaxVersion' = '4.0'
        'OData-Version'    = '4.0'
        Accept             = 'application/json'
    }
    if ($InSolution) { $headers['MSCRM.SolutionUniqueName'] = $schema.solution.uniqueName }
    $uri = if ($Path -match '^https?://') { $Path } else { "$api/$Path" }
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
#endregion

#region Deploy --------------------------------------------------------------------------
if ($EnableOrgAuditing) {
    $org = (Invoke-Dv -Path 'organizations?$select=organizationid,isauditenabled').value[0]
    if (-not $org.isauditenabled) {
        Invoke-Dv -Method Patch -Path "organizations($($org.organizationid))" -Body @{ isauditenabled = $true } | Out-Null
        Write-Host 'Enabled organization auditing.' -ForegroundColor Green
    }
}

# Publisher
$pub = (Invoke-Dv -Path "publishers?`$filter=uniquename eq '$($schema.publisher.uniqueName)'&`$select=publisherid").value | Select-Object -First 1
if (-not $pub) {
    Invoke-Dv -Method Post -Path 'publishers' -Body @{
        uniquename = $schema.publisher.uniqueName; friendlyname = $schema.publisher.friendlyName
        customizationprefix = $schema.publisher.prefix; customizationoptionvalueprefix = [int]$schema.publisher.optionValuePrefix
    } | Out-Null
    $pub = (Invoke-Dv -Path "publishers?`$filter=uniquename eq '$($schema.publisher.uniqueName)'&`$select=publisherid").value[0]
    Write-Host "Created publisher $($schema.publisher.uniqueName)" -ForegroundColor Green
}

# Solution
$sol = (Invoke-Dv -Path "solutions?`$filter=uniquename eq '$($schema.solution.uniqueName)'&`$select=solutionid").value | Select-Object -First 1
if (-not $sol) {
    Invoke-Dv -Method Post -Path 'solutions' -Body @{
        uniquename = $schema.solution.uniqueName; friendlyname = $schema.solution.friendlyName; version = $schema.solution.version
        'publisherid@odata.bind' = "/publishers($($pub.publisherid))"
    } | Out-Null
    Write-Host "Created solution $($schema.solution.uniqueName)" -ForegroundColor Green
}

# Tables + columns
foreach ($t in $schema.tables) {
    $existing = Invoke-Dv -Path "EntityDefinitions(LogicalName='$($t.logicalName)')?`$select=LogicalName" -AllowNotFound
    if (-not $existing) {
        Invoke-Dv -InSolution -Method Post -Path 'EntityDefinitions' -Body (New-TableBody $t) | Out-Null
        Write-Host "Created table $($t.logicalName)" -ForegroundColor Green
    } else { Write-Host "Table $($t.logicalName) exists" }

    foreach ($c in $t.columns) {
        $has = Invoke-Dv -Path "EntityDefinitions(LogicalName='$($t.logicalName)')/Attributes(LogicalName='$($c.logicalName)')?`$select=LogicalName" -AllowNotFound
        if ($has) { continue }
        Invoke-Dv -InSolution -Method Post -Path "EntityDefinitions(LogicalName='$($t.logicalName)')/Attributes" -Body (New-AttributeBody $c) | Out-Null
        Write-Host "  + $($t.logicalName).$($c.logicalName)" -ForegroundColor Green
    }
}

# Lookups (after all tables exist)
foreach ($l in $schema.lookups) {
    $has = Invoke-Dv -Path "EntityDefinitions(LogicalName='$($l.table)')/Attributes(LogicalName='$($l.logicalName)')?`$select=LogicalName" -AllowNotFound
    if ($has) { continue }
    Invoke-Dv -InSolution -Method Post -Path 'RelationshipDefinitions' -Body (New-LookupBody $l) | Out-Null
    Write-Host "  + lookup $($l.table).$($l.logicalName) -> $($l.target)" -ForegroundColor Green
}

# Alternate keys (index build runs asynchronously in Dataverse)
foreach ($t in $schema.tables) {
    foreach ($k in @(Get-Prop $t 'keys' @())) {
        $has = (Invoke-Dv -Path "EntityDefinitions(LogicalName='$($t.logicalName)')/Keys?`$filter=LogicalName eq '$($k.logicalName)'&`$select=LogicalName").value
        if ($has) { continue }
        Invoke-Dv -InSolution -Method Post -Path "EntityDefinitions(LogicalName='$($t.logicalName)')/Keys" -Body (New-KeyBody $k) | Out-Null
        Write-Host "  + key $($t.logicalName).$($k.logicalName)" -ForegroundColor Green
    }
}

Invoke-Dv -Method Post -Path 'PublishAllXml' -Body @{} | Out-Null
Write-Host "`nDone and published. Key indexes build in the background (Solution > table > Keys shows Active when ready)." -ForegroundColor Green
#endregion
