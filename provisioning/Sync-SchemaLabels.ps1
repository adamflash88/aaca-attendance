<#
.SYNOPSIS
    Brings EXISTING columns in line with schema/tables.json: choice option labels and column required level.
    (Deploy-Schema.ps1 only creates missing items; it never changes existing ones.) Re-runnable.

.EXAMPLE
    ./Sync-SchemaLabels.ps1 -EnvironmentUrl https://org12345.crm.dynamics.com -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $EnvironmentUrl,
    [string] $AccessToken,
    [switch] $UseDeviceCode
)
. (Join-Path $PSScriptRoot 'DataverseCommon.ps1')
$schema = Get-Content (Join-Path $PSScriptRoot '..\schema\tables.json') -Raw | ConvertFrom-Json
Connect-Dataverse -EnvironmentUrl $EnvironmentUrl -AccessToken $AccessToken -UseDeviceCode:$UseDeviceCode -SolutionUniqueName $schema.solution.uniqueName

$changedTables = [System.Collections.Generic.HashSet[string]]::new()
foreach ($t in $schema.tables) {
    foreach ($c in $t.columns) {
        $base = "EntityDefinitions(LogicalName='$($t.logicalName)')/Attributes(LogicalName='$($c.logicalName)')"

        # Required level
        $wantRequired = if ($c.PSObject.Properties['required'] -and $c.required) { 'ApplicationRequired' } else { 'None' }
        $attr = Invoke-Dv -Path "$base`?`$select=RequiredLevel,AttributeType" -AllowNotFound
        if (-not $attr) { Write-Warning "$($t.logicalName).$($c.logicalName) not deployed (run Deploy-Schema.ps1)"; continue }
        if ($attr.RequiredLevel.Value -ne $wantRequired -and $PSCmdlet.ShouldProcess("$($t.logicalName).$($c.logicalName)", "required level $($attr.RequiredLevel.Value) -> $wantRequired")) {
            $type = @{ String = 'StringAttributeMetadata'; Memo = 'MemoAttributeMetadata'; DateTime = 'DateTimeAttributeMetadata'; Picklist = 'PicklistAttributeMetadata'
                       Boolean = 'BooleanAttributeMetadata'; Integer = 'IntegerAttributeMetadata' }[$attr.AttributeType]
            $full = Invoke-Dv -Path "$base/Microsoft.Dynamics.CRM.$type"
            $h = [ordered]@{ '@odata.type' = "Microsoft.Dynamics.CRM.$type" }
            foreach ($p in $full.PSObject.Properties) { if ($p.Name -notlike '@odata*') { $h[$p.Name] = $p.Value } }
            $h.RequiredLevel.Value = $wantRequired
            Invoke-Dv -Method Put -Path $base -Body $h -ExtraHeaders @{ 'MSCRM.MergeLabels' = 'true' } | Out-Null
            Write-Host "  $($t.logicalName).$($c.logicalName): required -> $wantRequired" -ForegroundColor Green
            [void]$changedTables.Add($t.logicalName)
        }

        # Choice labels
        if ($c.type -ne 'choice') { continue }
        $live = Invoke-Dv -Path "$base/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?`$select=LogicalName&`$expand=OptionSet(`$select=Options)"
        foreach ($o in $c.options) {
            $value = [int]$o[0]; $want = [string]$o[1]
            $cur = $live.OptionSet.Options | Where-Object Value -eq $value | Select-Object -First 1
            if (-not $cur) { Write-Warning "$($t.logicalName).$($c.logicalName): option $value missing (add it in the maker portal or recreate)"; continue }
            $curLabel = $cur.Label.UserLocalizedLabel.Label
            if ($curLabel -ne $want -and $PSCmdlet.ShouldProcess("$($t.logicalName).$($c.logicalName) $value", "label '$curLabel' -> '$want'")) {
                Invoke-Dv -Method Post -Path 'UpdateOptionValue' -Body @{
                    EntityLogicalName = $t.logicalName; AttributeLogicalName = $c.logicalName; Value = $value
                    Label = New-Label $want; MergeLabels = $true; SolutionUniqueName = $schema.solution.uniqueName } | Out-Null
                Write-Host "  $($t.logicalName).$($c.logicalName) [$value]: '$curLabel' -> '$want'" -ForegroundColor Green
                [void]$changedTables.Add($t.logicalName)
            }
        }
    }
}

if ($changedTables.Count -and -not $WhatIfPreference) {
    $xml = '<importexportxml><entities>' + (($changedTables | ForEach-Object { "<entity>$_</entity>" }) -join '') + '</entities></importexportxml>'
    Invoke-Dv -Method Post -Path 'PublishXml' -Body @{ ParameterXml = $xml } | Out-Null
    Write-Host "Published: $($changedTables -join ', ')" -ForegroundColor Green
} elseif (-not $changedTables.Count) { Write-Host 'Schema labels and required levels already match tables.json.' }
