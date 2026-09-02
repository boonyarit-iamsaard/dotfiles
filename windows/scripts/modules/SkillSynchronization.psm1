Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ManagedWindowsLinks.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'SkillInventory.psm1') -Force

function Invoke-SkillGit {
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [Parameter(Mandatory)] [string[]] $Arguments
    )

    $effectiveArguments = @('-c', "safe.directory=$($Configuration.SkillsRepository)") + $Arguments
    $previousErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git @effectiveArguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed:`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

function Initialize-SkillsCheckout {
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [Collections.Generic.List[string]] $Messages,
        [switch] $ReadOnly,
        [switch] $NoPull
    )

    $repository = $Configuration.SkillsRepository
    if (Test-Path -LiteralPath $repository -PathType Container) {
        if (-not (Test-Path -LiteralPath (Join-Path $repository '.git') -PathType Container)) {
            throw "Skills checkout is not a Git repository: $repository"
        }
    }
    else {
        if ($ReadOnly -or $NoPull) {
            throw "Skills checkout is missing: $repository. Run update-skills.ps1 once without -DryRun, -Check, or -NoPull to clone it."
        }

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $repository) | Out-Null
        $Messages.Add("Clone: $($Configuration.Manifest.repository.url) -> $repository")
        $null = Invoke-SkillGit -Configuration $Configuration -Arguments @(
            'clone', [string] $Configuration.Manifest.repository.url, $repository
        )
    }

    if ($NoPull -or $ReadOnly) {
        return
    }

    $status = @(Invoke-SkillGit -Configuration $Configuration -Arguments @('-C', $repository, 'status', '--porcelain'))
    if ($status.Count -gt 0) {
        throw "Skills checkout has local changes; refusing to pull: $repository"
    }

    $Messages.Add("Pull: $repository")
    $null = Invoke-SkillGit -Configuration $Configuration -Arguments @('-C', $repository, 'pull', '--ff-only')
}

function Read-ManagedSkillState {
    param([Parameter(Mandatory)] [string] $Path)

    $managed = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $managed
    }

    try {
        $payload = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
        if ($payload.version -ne 1) {
            throw 'unsupported version'
        }
        foreach ($entry in @($payload.links)) {
            $managed["$($entry.consumer)/$($entry.name)"] = [pscustomobject]@{
                Consumer = [string] $entry.consumer
                Name = [string] $entry.name
                Source = [string] $entry.source
            }
        }
    }
    catch {
        throw "Invalid skills state manifest '$Path': $($_.Exception.Message)"
    }
    return $managed
}

function Get-HistoricalSkillBlobs {
    param([Parameter(Mandatory)] [object] $Configuration)

    $blobs = @{}
    $objects = Invoke-SkillGit -Configuration $Configuration -Arguments @(
        '-C', $Configuration.SkillsRepository, 'rev-list', '--objects', '--all'
    )
    foreach ($line in $objects) {
        $text = [string] $line
        if ($text -notmatch '^[0-9a-f]+\s+skills/[^/]+/([^/]+)/(.*)$') {
            continue
        }
        $key = "$($Matches[1])/$($Matches[2])"
        if (-not $blobs.ContainsKey($key)) {
            $blobs[$key] = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        }
        $objectId = $text.Substring(0, $text.IndexOf(' '))
        $null = $blobs[$key].Add($objectId)
    }
    return $blobs
}

function Get-SkillFiles {
    param([Parameter(Mandatory)] [string] $Root)

    $files = @{}
    foreach ($file in Get-ChildItem -File -Recurse -Force -LiteralPath $Root) {
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Copied skill contains a link and cannot be migrated safely: $($file.FullName)"
        }
        $relative = $file.FullName.Substring($Root.TrimEnd('\').Length + 1).Replace('\', '/')
        $files[$relative] = $file.FullName
    }
    return $files
}

function Get-SkillBlobId {
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [Parameter(Mandatory)] [string] $Path
    )

    $result = @(Invoke-SkillGit -Configuration $Configuration -Arguments @('hash-object', '--', $Path))
    return ([string] $result[0]).Trim()
}

function Test-HistoricalSkillCopy {
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [hashtable] $HistoricalBlobs
    )

    $files = Get-SkillFiles -Root $Path
    if ($files.Count -eq 0) {
        return $false
    }
    foreach ($relative in $files.Keys) {
        $key = "$Name/$relative"
        if (-not $HistoricalBlobs.ContainsKey($key)) {
            return $false
        }
        $blob = Get-SkillBlobId -Configuration $Configuration -Path $files[$relative]
        if (-not $HistoricalBlobs[$key].Contains($blob)) {
            return $false
        }
    }
    return $true
}

function Test-SkillDirectoryMatch {
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [Parameter(Mandatory)] [string] $Left,
        [Parameter(Mandatory)] [string] $Right
    )

    $leftFiles = Get-SkillFiles -Root $Left
    $rightFiles = Get-SkillFiles -Root $Right
    if ($leftFiles.Count -ne $rightFiles.Count) {
        return $false
    }
    foreach ($relative in $leftFiles.Keys) {
        if (-not $rightFiles.ContainsKey($relative)) {
            return $false
        }
        $leftBlob = Get-SkillBlobId -Configuration $Configuration -Path $leftFiles[$relative]
        $rightBlob = Get-SkillBlobId -Configuration $Configuration -Path $rightFiles[$relative]
        if ($leftBlob -ne $rightBlob) {
            return $false
        }
    }
    return $true
}

function New-SkillAction {
    param(
        [Parameter(Mandatory)] [string] $Kind,
        [Parameter(Mandatory)] [object] $Skill,
        [string] $ExistingSource
    )

    return [pscustomobject]@{
        Kind = $Kind
        Consumer = $Skill.Consumer
        Name = $Skill.Name
        Target = $Skill.Target
        Source = $Skill.Source
        ExistingSource = $ExistingSource
    }
}

function Get-SkillReconciliationPlan {
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [Parameter(Mandatory)] [object] $Inventory,
        [Parameter(Mandatory)] [hashtable] $Managed,
        [switch] $Migrate
    )

    $desired = $Inventory.Skills
    $actions = [Collections.Generic.List[object]]::new()
    $historicalBlobs = $null

    foreach ($key in @($desired.Keys | Sort-Object)) {
        $skill = $desired[$key]
        $linkTarget = Get-ManagedLinkTarget -Path $skill.Target
        if ($linkTarget) {
            if (Test-PathEquivalent -Left $linkTarget -Right $skill.Source) {
                continue
            }
            $known = $Managed.ContainsKey($key) -and
                (Test-PathEquivalent -Left $linkTarget -Right $Managed[$key].Source)
            if (-not $known) {
                throw "Unmanaged symlink collision: $($skill.Target) -> $linkTarget"
            }
            $actions.Add((New-SkillAction -Kind 'unlink' -Skill $skill -ExistingSource $linkTarget))
            $actions.Add((New-SkillAction -Kind 'link' -Skill $skill))
            continue
        }

        if (Test-Path -LiteralPath $skill.Target) {
            if (-not $Migrate -or -not (Test-Path -LiteralPath $skill.Target -PathType Container)) {
                throw "Unmanaged path collision: $($skill.Target). Use -Migrate only for an unchanged copied skill."
            }
            $verified = if ($skill.Provenance -eq 'upstream') {
                if ($null -eq $historicalBlobs) {
                    $historicalBlobs = Get-HistoricalSkillBlobs -Configuration $Configuration
                }
                Test-HistoricalSkillCopy -Configuration $Configuration -Path $skill.Target -Name $skill.Name -HistoricalBlobs $historicalBlobs
            }
            else {
                Test-SkillDirectoryMatch -Configuration $Configuration -Left $skill.Target -Right $skill.Source
            }
            if (-not $verified) {
                throw "Refusing to migrate modified or unverified skill: $($skill.Target)"
            }
            $actions.Add((New-SkillAction -Kind 'move' -Skill $skill))
        }
        $actions.Add((New-SkillAction -Kind 'link' -Skill $skill))
    }

    foreach ($key in @($Managed.Keys | Sort-Object)) {
        if ($desired.ContainsKey($key)) {
            continue
        }
        $entry = $Managed[$key]
        if (-not $Inventory.ConsumerRoots.ContainsKey($entry.Consumer)) {
            throw "Unknown skills consumer in managed state: $($entry.Consumer)"
        }
        $target = Join-Path $Inventory.ConsumerRoots[$entry.Consumer] $entry.Name
        if (-not (Get-Item -Force -LiteralPath $target -ErrorAction SilentlyContinue)) {
            continue
        }
        $linkTarget = Get-ManagedLinkTarget -Path $target
        if (-not $linkTarget -or -not (Test-PathEquivalent -Left $linkTarget -Right $entry.Source)) {
            throw "Stale managed skill was replaced outside the synchronizer: $target"
        }
        $skill = [pscustomobject]@{
            Consumer = $entry.Consumer
            Name = $entry.Name
            Source = $entry.Source
            Target = $target
        }
        $actions.Add((New-SkillAction -Kind 'unlink' -Skill $skill -ExistingSource $linkTarget))
    }

    return @($actions)
}

function Write-ManagedSkillState {
    param(
        [Parameter(Mandatory)] [string] $StatePath,
        [Parameter(Mandatory)] [hashtable] $Desired
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $StatePath) | Out-Null
    $links = @(
        foreach ($key in @($Desired.Keys | Sort-Object)) {
            $skill = $Desired[$key]
            [ordered]@{
                consumer = $skill.Consumer
                name = $skill.Name
                source = $skill.Source
            }
        }
    )
    $temporary = "$StatePath.tmp"
    [ordered]@{ version = 1; links = $links } |
        ConvertTo-Json -Depth 4 |
        Set-Content -Encoding UTF8 -LiteralPath $temporary
    Move-Item -Force -LiteralPath $temporary -Destination $StatePath
}

function Invoke-SkillReconciliationPlan {
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $Actions,
        [Parameter(Mandatory)] [hashtable] $Desired
    )

    $backupDirectory = Join-Path $Configuration.BackupRoot (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')
    $completedMoves = [Collections.Generic.List[object]]::new()
    $removedLinks = [Collections.Generic.List[object]]::new()
    $createdLinks = [Collections.Generic.List[object]]::new()

    try {
        foreach ($action in @($Actions | Where-Object Kind -eq 'move')) {
            $archive = Join-Path $backupDirectory "removed\$($action.Consumer)\$($action.Name)"
            $snapshot = Join-Path $backupDirectory "snapshot\$($action.Consumer)\$($action.Name)"
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $archive) | Out-Null
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $snapshot) | Out-Null
            Copy-Item -Recurse -Force -LiteralPath $action.Target -Destination $snapshot
            Move-Item -LiteralPath $action.Target -Destination $archive
            $action | Add-Member -NotePropertyName Archive -NotePropertyValue $archive
            $completedMoves.Add($action)
        }

        foreach ($action in @($Actions | Where-Object Kind -eq 'unlink')) {
            Remove-ManagedLink -Path $action.Target
            $removedLinks.Add($action)
        }

        foreach ($action in @($Actions | Where-Object Kind -eq 'link')) {
            New-ManagedLink -Path $action.Target -Source $action.Source -Directory $true
            $createdLinks.Add($action)
        }

        Write-ManagedSkillState -StatePath $Configuration.StatePath -Desired $Desired
    }
    catch {
        for ($index = $createdLinks.Count - 1; $index -ge 0; $index--) {
            $action = $createdLinks[$index]
            if (Test-ManagedLink -Path $action.Target -Source $action.Source) {
                Remove-ManagedLink -Path $action.Target
            }
        }
        for ($index = $removedLinks.Count - 1; $index -ge 0; $index--) {
            $action = $removedLinks[$index]
            if (-not (Test-Path -LiteralPath $action.Target)) {
                New-ManagedLink -Path $action.Target -Source $action.ExistingSource -Directory $true
            }
        }
        for ($index = $completedMoves.Count - 1; $index -ge 0; $index--) {
            $action = $completedMoves[$index]
            if ((Test-Path -LiteralPath $action.Archive) -and -not (Test-Path -LiteralPath $action.Target)) {
                Move-Item -LiteralPath $action.Archive -Destination $action.Target
            }
        }
        throw
    }

    if ($completedMoves.Count -gt 0) {
        return $backupDirectory
    }
    return $null
}

function Invoke-SkillSynchronization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Configuration,
        [switch] $DryRun,
        [switch] $Check,
        [switch] $Migrate,
        [switch] $NoPull
    )

    if ($DryRun -and $Check) {
        throw '-DryRun and -Check are mutually exclusive.'
    }
    if ($Configuration.Manifest.version -ne 1) {
        throw "Unsupported skills manifest version: $($Configuration.Manifest.version)"
    }

    $messages = [Collections.Generic.List[string]]::new()
    Initialize-SkillsCheckout -Configuration $Configuration -Messages $messages -ReadOnly:($DryRun -or $Check) -NoPull:$NoPull
    $inventory = Get-SkillInventory -Manifest $Configuration.Manifest -DotfilesRoot $Configuration.DotfilesRoot `
        -SkillsRepository $Configuration.SkillsRepository -UserHome $Configuration.UserHome
    $managed = Read-ManagedSkillState -Path $Configuration.StatePath
    $plan = @(Get-SkillReconciliationPlan -Configuration $Configuration -Inventory $inventory -Managed $managed -Migrate:$Migrate)

    $backupDirectory = $null
    if (-not $DryRun -and -not $Check) {
        $backupDirectory = Invoke-SkillReconciliationPlan -Configuration $Configuration -Actions $plan -Desired $inventory.Skills
    }

    return [pscustomobject]@{
        Actions = $plan
        Messages = @($messages)
        BackupDirectory = $backupDirectory
        ExitCode = if ($Check -and $plan.Count -gt 0) { 1 } else { 0 }
        Synchronized = -not $DryRun -and -not $Check
    }
}

Export-ModuleMember -Function 'Invoke-SkillSynchronization'
