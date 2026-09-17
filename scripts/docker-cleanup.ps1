[CmdletBinding(SupportsShouldProcess)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion -lt [Version]'7.0') {
    throw 'PowerShell 7.0 or newer is required. Run this script with pwsh.exe.'
}

function Get-LogTimestamp {
    Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Output')]
        [string] $Level,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Message
    )

    $style = switch ($Level) {
        'Info' { @{ Color = 'Blue'; Symbol = [char]::ConvertFromUtf32(0x2139) } }
        'Success' { @{ Color = 'Green'; Symbol = [char]::ConvertFromUtf32(0x2705) } }
        'Warning' { @{ Color = 'Yellow'; Symbol = [char]::ConvertFromUtf32(0x26A0) } }
        'Error' { @{ Color = 'Red'; Symbol = [char]::ConvertFromUtf32(0x274C) } }
        'Output' { @{ Color = 'Cyan'; Symbol = [char]::ConvertFromUtf32(0x1F539) } }
    }

    $text = if ([string]::IsNullOrWhiteSpace($Message)) { '---' } else { $Message }
    Write-Host "[$(Get-LogTimestamp)] $($style.Symbol)  $text" -ForegroundColor $style.Color
}

function Invoke-DockerLogged {
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    $output = & docker @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    foreach ($line in @($output)) {
        $text = [string] $line
        if ($text -match 'error') {
            Write-Host "[$(Get-LogTimestamp)] $([char]::ConvertFromUtf32(0x1F534))  $text" -ForegroundColor Red
        }
        else {
            Write-Log -Level Output -Message $text
        }
    }

    return $exitCode -eq 0
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'The docker command was not found. Install and start Docker Desktop, then try again.'
}

Write-Host "[$(Get-LogTimestamp)] $([char]::ConvertFromUtf32(0x1F680))  Starting Docker system cleanup..." -ForegroundColor Yellow

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'The Docker daemon is not running. Start Docker Desktop, then try again.'
}

$hadFailure = $false
Write-Log -Level Info -Message 'Checking for containers to remove...'
$containerOutput = @(& docker ps -aq 2>&1)
if ($LASTEXITCODE -ne 0) {
    $containerOutput | ForEach-Object { Write-Log -Level Error -Message ([string] $_) }
    throw 'Failed to list Docker containers.'
}

$containerIds = @($containerOutput | ForEach-Object { ([string] $_).Trim() } | Where-Object { $_ })
if ($containerIds.Count -eq 0) {
    Write-Log -Level Warning -Message 'No containers found. Skipping removal.'
}
elseif ($PSCmdlet.ShouldProcess("$($containerIds.Count) Docker container(s)", 'Force remove')) {
    if (Invoke-DockerLogged -Arguments (@('rm', '-f') + $containerIds)) {
        Write-Log -Level Success -Message 'All containers removed.'
    }
    else {
        Write-Log -Level Error -Message 'Failed to remove some containers.'
        $hadFailure = $true
    }
}

$pruneOperations = @(
    @{ Target = 'unused Docker volumes'; Arguments = @('volume', 'prune', '-af'); Success = 'Volumes pruned.'; Failure = 'Failed to prune volumes.'; Optional = $false }
    @{ Target = 'unused Docker networks'; Arguments = @('network', 'prune', '-f'); Success = 'Networks pruned.'; Failure = 'Failed to prune networks.'; Optional = $false }
    @{ Target = 'Docker builder cache'; Arguments = @('builder', 'prune', '-af'); Success = 'Builder cache pruned.'; Failure = 'Builder cache prune failed (BuildKit might be disabled or unsupported). Continuing...'; Optional = $true }
)

foreach ($operation in $pruneOperations) {
    Write-Log -Level Info -Message "Pruning $($operation.Target.Replace('Docker ', ''))..."
    if (-not $PSCmdlet.ShouldProcess($operation.Target, 'Prune')) {
        continue
    }

    if (Invoke-DockerLogged -Arguments $operation.Arguments) {
        Write-Log -Level Success -Message $operation.Success
    }
    elseif ($operation.Optional) {
        Write-Log -Level Warning -Message $operation.Failure
    }
    else {
        Write-Log -Level Error -Message $operation.Failure
        $hadFailure = $true
    }
}

Write-Host "`n--- Final disk usage ---" -ForegroundColor Yellow
if (-not (Invoke-DockerLogged -Arguments @('system', 'df'))) {
    Write-Log -Level Error -Message 'Failed to report Docker disk usage.'
    $hadFailure = $true
}

if ($hadFailure) {
    throw 'Docker cleanup finished with one or more errors.'
}

Write-Host "`n[$(Get-LogTimestamp)] $([char]::ConvertFromUtf32(0x1F389))  Docker cleanup process finished." -ForegroundColor Green
