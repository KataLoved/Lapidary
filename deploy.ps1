<#
.SYNOPSIS
    Copies the runtime part of BlackDiamonds into the game AddOns folder.

.DESCRIPTION
    Only what the client actually loads is copied: BlackDiamonds.toc,
    BlackDiamonds.lua, embeds.xml, Modules/, Libs/, Localization/.
    Everything else (docs/, *.md, .git, .vscode, deploy.ps1) stays out of the
    game folder.

    Files present in the target but no longer in the source are removed, so a
    renamed or deleted module cannot linger and get loaded by a stale TOC.

.PARAMETER GamePath
    AddOns directory of the client.

.PARAMETER WhatIf
    Show what would change without touching anything.

.PARAMETER Force
    Required when the target folder contains a .git directory: deploying over a
    working repository would overwrite files git is tracking.

.EXAMPLE
    .\deploy.ps1 -WhatIf
    .\deploy.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $GamePath = 'D:\Games\World of Warcraft Sirus\Interface\AddOns',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$AddonName = 'BlackDiamonds'
$SourceRoot = $PSScriptRoot
$Target = Join-Path $GamePath $AddonName

$RootFiles = @(
    'BlackDiamonds.toc',
    'BlackDiamonds.lua',
    'embeds.xml'
)
$Folders = @(
    'Modules',
    'Libs',
    'Localization'
)

if (-not (Test-Path -LiteralPath $GamePath)) {
    throw "AddOns folder not found: $GamePath"
}

foreach ($f in $RootFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $SourceRoot $f))) {
        throw "Missing source file: $f"
    }
}

if ((Test-Path -LiteralPath (Join-Path $Target '.git')) -and -not $Force) {
    Write-Warning "$Target is a git working copy."
    Write-Warning 'Deploying would overwrite tracked files. Commit or stash there first,'
    Write-Warning 'then re-run with -Force.'
    return
}

$planned = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$copyList = New-Object System.Collections.Generic.List[object]

foreach ($f in $RootFiles) {
    [void]$planned.Add($f)
    $copyList.Add([pscustomobject]@{
        Source   = Join-Path $SourceRoot $f
        Relative = $f
    })
}

foreach ($folder in $Folders) {
    $src = Join-Path $SourceRoot $folder
    if (-not (Test-Path -LiteralPath $src)) {
        throw "Missing source folder: $folder"
    }
    Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($SourceRoot.Length).TrimStart('\')
        [void]$planned.Add($rel)
        $copyList.Add([pscustomobject]@{
            Source   = $_.FullName
            Relative = $rel
        })
    }
}

$copied = 0
$skipped = 0

foreach ($item in $copyList) {
    $dest = Join-Path $Target $item.Relative
    $destDir = Split-Path -Parent $dest

    $same = $false
    if (Test-Path -LiteralPath $dest) {
        $same = (Get-FileHash -LiteralPath $item.Source).Hash -eq (Get-FileHash -LiteralPath $dest).Hash
    }

    if ($same) {
        $skipped++
        continue
    }

    if ($PSCmdlet.ShouldProcess($item.Relative, 'copy')) {
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }
        Copy-Item -LiteralPath $item.Source -Destination $dest -Force
    }
    $copied++
}

$removed = 0
if (Test-Path -LiteralPath $Target) {
    $existing = @(Get-ChildItem -LiteralPath $Target -Recurse -File -Force)
    foreach ($file in $existing) {
        $rel = $file.FullName.Substring($Target.Length).TrimStart('\')
        if ($rel -like '.git\*' -or $rel -eq '.git') { continue }
        if (-not $planned.Contains($rel)) {
            if ($PSCmdlet.ShouldProcess($rel, 'remove stale')) {
                Remove-Item -LiteralPath $file.FullName -Force
            }
            $removed++
        }
    }
}

$version = (Select-String -LiteralPath (Join-Path $SourceRoot 'BlackDiamonds.toc') -Pattern '^##\s*Version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()

Write-Host ''
Write-Host "BlackDiamonds $version -> $Target"
Write-Host "  copied:    $copied"
Write-Host "  unchanged: $skipped"
Write-Host "  removed:   $removed"
Write-Host ''
Write-Host 'Reload the client UI (/reload) to pick up the changes.'
