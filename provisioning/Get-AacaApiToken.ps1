<#
.SYNOPSIS
    Returns an access token for another Microsoft API (Power Automate, SharePoint) from the cached Dataverse sign-in
    (DataverseCommon.ps1 keeps a DPAPI-encrypted refresh token). Used by flow test/run helpers. Never prints it.

.EXAMPLE
    $t = ./Get-AacaApiToken.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Scope 'https://service.flow.microsoft.com//.default'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $Scope
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl | Out-Null   # refreshes the cache if needed
$cache = Get-Content (Get-DvTokenCachePath) -Raw | ConvertFrom-Json
$refresh = Unprotect-DvText $cache.refresh
if (-not $refresh) { throw 'No cached refresh token; run any provisioning script once to sign in.' }
$r = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$script:DvTenantId/oauth2/v2.0/token" -Body @{
    grant_type = 'refresh_token'; client_id = $script:DvClientId; refresh_token = $refresh; scope = "$Scope offline_access" }
$r.access_token
