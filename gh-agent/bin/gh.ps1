# PowerShell twin of the gh wrapper beside it; see that file for the rationale
# and token setup. GH_TOKEN is process-wide in PowerShell, so it is restored
# after the call instead of leaking into the caller's session.
Set-StrictMode -Version Latest

# Skip this directory: PowerShell also counts the extensionless bash wrapper
# as an application.
$real = Get-Command -Name gh -CommandType Application -All -ErrorAction SilentlyContinue |
    Where-Object { (Split-Path -Parent $_.Source) -ne $PSScriptRoot } |
    Select-Object -First 1
if (-not $real) {
    [Console]::Error.WriteLine('gh wrapper: no gh binary found on PATH (scoop install gh)')
    exit 127
}

$tokenName = if ($args.Count -gt 0 -and $args[0] -eq 'project') { 'project-token' } else { 'token' }
$tokenFile = Join-Path $HOME ".config\gh-agent\$tokenName"
$previousToken = $env:GH_TOKEN
try {
    if (Test-Path -LiteralPath $tokenFile -PathType Leaf) {
        $env:GH_TOKEN = (Get-Content -Raw -LiteralPath $tokenFile).Trim()
    }
    if ($MyInvocation.ExpectingInput) {
        $input | & $real.Source @args
    }
    else {
        & $real.Source @args
    }
}
finally {
    $env:GH_TOKEN = $previousToken
}
exit $LASTEXITCODE
