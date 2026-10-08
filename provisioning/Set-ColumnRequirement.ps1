<#
.SYNOPSIS
    Changes the requirement level of an existing column (Deploy-Schema.ps1 only creates missing columns, it never alters
    existing ones), then publishes the table.

.EXAMPLE
    ./Set-ColumnRequirement.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -Table aaca_absencenotice -Column aaca_absencereason -Level None
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [Parameter(Mandatory)] [string] $Table,
    [Parameter(Mandatory)] [string] $Column,
    [ValidateSet('None', 'Recommended', 'ApplicationRequired')] [string] $Level = 'None'
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl

$path = "EntityDefinitions(LogicalName='$Table')/Attributes(LogicalName='$Column')"
$attr = Invoke-Dv -Path $path
if ($attr.RequiredLevel.Value -eq $Level) { Write-Host "$Table.$Column is already $Level"; return }
$attr.RequiredLevel.Value = $Level
# PUT needs the concrete metadata type and no read-only navigation/annotation properties.
$body = [ordered]@{}
foreach ($p in $attr.PSObject.Properties) { if ($p.Name -notlike '*@odata.context' -and $p.Name -ne 'Targets@odata.type') { $body[$p.Name] = $p.Value } }
Invoke-Dv -Method Put -Path $path -Body $body -ExtraHeaders @{ 'MSCRM.MergeLabels' = 'true' } | Out-Null
Invoke-Dv -Method Post -Path 'PublishXml' -Body @{ ParameterXml = "<importexportxml><entities><entity>$Table</entity></entities></importexportxml>" } | Out-Null
Write-Host "$Table.$Column requirement set to $Level and published" -ForegroundColor Green
