<#
.SYNOPSIS
    Adds choice options that schema/tables.json defines but the environment's existing choice columns lack
    (Deploy-Schema.ps1 creates missing columns but never alters existing ones). Never removes or renumbers options.
    Publishes the changed tables.

.EXAMPLE
    ./Add-ChoiceOptions.ps1 -EnvironmentUrl https://org42baa05f.crm.dynamics.com -WhatIf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [switch] $WhatIf
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
$schema = Get-Content (Join-Path $PSScriptRoot '..\schema\tables.json') -Raw | ConvertFrom-Json
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -SolutionUniqueName $schema.solution.uniqueName

$changedTables = [System.Collections.Generic.List[string]]::new()
foreach ($t in $schema.tables) {
    foreach ($c in @($t.columns | Where-Object { $_.type -eq 'choice' })) {
        $path = "EntityDefinitions(LogicalName='$($t.logicalName)')/Attributes(LogicalName='$($c.logicalName)')/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?`$select=LogicalName&`$expand=OptionSet(`$select=Options)"
        $attr = Invoke-Dv -Path $path -AllowNotFound
        if (-not $attr) { continue }   # column not in this environment yet: Deploy-Schema.ps1 creates it whole
        $have = @($attr.OptionSet.Options | ForEach-Object { [int]$_.Value })
        foreach ($o in $c.options) {
            if ([int]$o[0] -in $have) { continue }
            Write-Host "$($t.logicalName).$($c.logicalName): add $($o[0]) '$($o[1])'" -ForegroundColor Green
            if ($WhatIf) { continue }
            Invoke-Dv -Method Post -Path 'InsertOptionValue' -InSolution -Body @{
                EntityLogicalName = $t.logicalName; AttributeLogicalName = $c.logicalName; Value = [int]$o[0]
                Label = New-Label ([string]$o[1]); SolutionUniqueName = $schema.solution.uniqueName } | Out-Null
            if ($t.logicalName -notin $changedTables) { $changedTables.Add($t.logicalName) }
        }
    }
}
if ($changedTables.Count) {
    $xml = '<importexportxml><entities>' + (($changedTables | ForEach-Object { "<entity>$_</entity>" }) -join '') + '</entities></importexportxml>'
    Invoke-Dv -Method Post -Path 'PublishXml' -Body @{ ParameterXml = $xml } | Out-Null
    Write-Host "Published: $($changedTables -join ', ')"
} elseif (-not $WhatIf) { Write-Host 'No missing choice options.' }
