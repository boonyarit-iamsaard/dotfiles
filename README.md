# Windows developer dotfiles

Native Windows developer tooling and configuration managed with PowerShell and
Scoop. This branch is independent from the macOS (`main`) and WSL (`wsl`)
branches.

## Scope

- Scoop is the package manager for automated setup and updates.
- `bootstrap.ps1` performs fresh-machine setup.
- `scripts/update-system.ps1` updates only developer packages declared in
  `manifests/packages.json`.
- `scripts/link-dotfiles.ps1` creates Stow-like symbolic links from Windows
  configuration locations into this repository.
- `scripts/update-skills.ps1` maintains shared Codex CLI and Claude Code skills
  from a separate, read-only checkout.

Windows Update, drivers, firmware, Store updates, services, registry tuning,
and automatic reboots are deliberately outside the update script's scope.

## Prerequisites

Before running the repository scripts, the machine needs:

- Native Windows 10 or Windows 11.
- PowerShell 7.0 or newer (`pwsh`). Windows PowerShell 5.1 is not supported.
- Internet access to GitHub and Scoop package sources during setup.
- A standard, non-administrator PowerShell 7 terminal for Scoop and bootstrap.
- Windows Developer Mode enabled so the standard user can create symbolic
  links. Enabling it once requires administrator approval.
- An execution policy that permits local scripts. This setup uses
  `RemoteSigned` for the current user.

Open Developer Mode directly with:

```powershell
Start-Process 'ms-settings:developers'
```

On Windows 11 25H2 and newer, the toggle is under **Settings > System >
Advanced > For developers**. Search Settings for `Developer Mode` if the path
differs on an older Windows release.

Do not enable Device Portal or Device discovery; neither is required for these
dotfiles.

## Fresh-machine setup

### 1. Prepare PowerShell 7, Scoop, and Git

PowerShell 7 is a stage-zero prerequisite and is intentionally not installed by
bootstrap. From a non-administrator PowerShell 7 terminal, install Scoop and
Git when they are not already available:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install git
```

Confirm both commands are available:

```powershell
scoop --version
git --version
pwsh --version
```

### 2. Clone the Windows branch

```powershell
git clone --branch windows https://github.com/boonyarit-iamsaard/dotfiles.git "$HOME\dotfiles"
Set-Location "$HOME\dotfiles"
git branch --show-current
```

The branch command must print `windows`. The repository is public, so cloning
does not require GitHub authentication. Authentication is required only when
pushing; Git Credential Manager can prompt for it on the first push.

Configure commit identity if a new Git installation does not have it yet:

```powershell
git config --global user.name "Boonyarit Iamsa-ard"
git config --global user.email "boonyarit.iamsaard@gmail.com"
```

### 3. Bootstrap

From the repository root:

```powershell
.\bootstrap.ps1
```

Bootstrap verifies the platform, PowerShell version, execution policy, and
Developer Mode before it installs declared packages, creates configuration
links, clones or updates the skills checkout, links agent skills, and runs the
final verifier. It is safe to rerun after a partial setup.

## Verification

Bootstrap runs the verifier automatically. Run it independently at any time:

```powershell
.\scripts\verify-system.ps1
```

It checks:

- Windows and PowerShell prerequisites.
- The effective execution policy and Developer Mode.
- Git availability and the checked-out `windows` branch.
- Scoop availability and Scoop ownership of every declared package.
- Command availability for declared packages.
- The existence and exact destination of every managed symbolic link.
- The skills checkout and every managed Codex and Claude skill link.

For the initial lazygit setup, these manual checks provide additional detail:

```powershell
Get-ExecutionPolicy
scoop prefix lazygit
lazygit --version
lazygit --print-config-dir
Get-Item "$env:LOCALAPPDATA\lazygit\config.yml" | Format-List FullName, LinkType, Target
```

Expected results:

- The execution policy is `RemoteSigned`, `Unrestricted`, or `Bypass`.
- Scoop prints lazygit's installation directory.
- Lazygit prints a version and `%LOCALAPPDATA%\lazygit` as its config directory.
- `LinkType` is `SymbolicLink` and `Target` points into
  `dotfiles\config\lazygit\config.yml`.

Confirm idempotency by running bootstrap a second time. Existing packages and
correct links should be reported without being replaced.

## Shell configuration

The PowerShell 7 profile and its Oh My Posh themes are tracked in `powershell`
and linked into `%USERPROFILE%\Documents\PowerShell`:

```powershell
.\scripts\link-dotfiles.ps1 powershell
```

Oh My Posh renders a native equivalent of Starship's Nerd Font Symbols preset
from `powershell\oh-my-posh\nerd-font-symbols.omp.json` and is declared in
`manifests/packages.json`. The previous Catppuccin Mocha theme remains available
alongside it. One dependency is not a Scoop package and is installed separately:

- `Terminal-Icons` comes from the PowerShell Gallery:
  `Install-Module Terminal-Icons -Scope CurrentUser`. The profile imports it
  only when it is present.

The profile also provides:

- Vi line editing with `jj` as the escape chord, plus history-based
  prediction in list view. The cursor marks the mode: a blinking bar while
  inserting, a blinking block in command mode. This needs a terminal that
  understands `DECSCUSR`, such as Windows Terminal.
- `lzg` for lazygit.
- `link-dotfiles`, `update-skills`, `update-system` and `verify-system` as
  aliases for the matching scripts in `scripts`, so they run from any
  directory. The profile finds the checkout through its own symlink target
  rather than a hard-coded path.

A nerd font is required for the prompt glyphs. The `nerd-fonts` bucket
provides them.

## Daily use

Update the declared developer environment:

```powershell
.\scripts\update-system.ps1
```

Link or unlink one configuration package:

```powershell
.\scripts\link-dotfiles.ps1 lazygit
.\scripts\link-dotfiles.ps1 lazygit -Delete
```

The link script is idempotent and refuses to overwrite or delete unmanaged
files.

### Agent skills

Shared skills come from the separate fork at
`https://github.com/boonyarit-iamsaard/skills`, cloned by default to
`$HOME\skills`. The checkout remains a normal Git repository; skill folders are
linked individually into the user-wide discovery roots:

- Codex CLI: `$HOME\.agents\skills`
- Claude Code: `$HOME\.claude\skills`

Update the clean checkout with a fast-forward-only pull and reconcile both
consumers:

```powershell
.\scripts\update-skills.ps1
```

Preview changes or use the command in health checks without pulling:

```powershell
.\scripts\update-skills.ps1 -DryRun
.\scripts\update-skills.ps1 -Check
.\scripts\update-skills.ps1 -NoPull
```

The first conversion from copied skill directories must be previewed and then
run explicitly:

```powershell
.\scripts\update-skills.ps1 -DryRun -Migrate -NoPull
.\scripts\update-skills.ps1 -Migrate -NoPull
```

Migration accepts only unchanged files whose Git blobs occur in the fork's
history. It snapshots and archives verified copies under
`%LOCALAPPDATA%\dotfiles\skill-sync\backups`, refuses modified or unmanaged
collisions, and rolls completed moves back if link creation fails. The managed
link inventory is stored outside the repository at
`%LOCALAPPDATA%\dotfiles\skill-sync\managed-links.json`.

Only the promoted `engineering` and `productivity` buckets are installed from
the fork. The personal `commit-message` and `typescript-house-style` skills
live under `skills\shared` in this dotfiles repository and are declared
explicitly in `manifests\skills.json`.

## Manifests

- `manifests/packages.json` declares Scoop buckets and developer packages.
- `manifests/links.json` maps tracked files to native Windows destinations.
- `manifests/skills.json` declares the skills checkout, promoted categories,
  consumers, and locally owned skills.

Add future tools through these manifests so bootstrap, update, and verification
continue to share one source of truth.

## Troubleshooting

- **Scripts are disabled:** run
  `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, then open a new
  PowerShell terminal.
- **Scoop is not recognized:** open a new non-administrator PowerShell terminal
  after installation and rerun `scoop --version`.
- **Symlink privilege error:** confirm Developer Mode is enabled. Do not run the
  whole bootstrap as Administrator to work around it.
- **Target already exists:** the linker intentionally refuses to overwrite it.
  Inspect and back up the existing file yourself, then rerun the linker.
- **Skills checkout has local changes:** commit or discard those changes in
  `$HOME\skills`; the updater deliberately refuses to pull a dirty checkout.
- **Skill target already exists:** inspect it first. Use `-Migrate` only for an
  unchanged copied skill; modified or unrelated paths are never replaced.
- **Wrong branch:** switch explicitly with `git switch windows` before running
  setup or verification.
