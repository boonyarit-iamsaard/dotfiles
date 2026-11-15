# Windows developer dotfiles

Native Windows developer tooling and configuration managed with PowerShell and
Scoop. It lives in the `windows/` folder of the dotfiles checkout; run every
command below from that folder unless it says otherwise. Other platforms are
listed in the root [README.md](../README.md).

## Scope

- Scoop is the package manager for automated setup and updates.
- `bootstrap.ps1` performs fresh-machine setup.
- `scripts/update-system.ps1` updates only developer packages declared in
  `manifests/packages.json`, then reapplies `manifests/environment.json` because
  Scoop package upgrades can rewrite the user `PATH` and `JAVA_HOME`. It ends by
  running `scripts/check-manual-updates.ps1`, which only reports skill and
  vendored-payload updates that need a manual, reviewed step.
- `scripts/set-environment.ps1` persists declared user environment variables and
  `PATH` entries from `manifests/environment.json`.
- `scripts/set-node-toolchain.ps1` installs and activates the Node.js release in
  `manifests/node-toolchain.json`, applies the declared NVM mode, and enables
  Corepack.
- `scripts/link-dotfiles.ps1` creates Stow-like symbolic links from Windows
  configuration locations into this repository.
- `gh-agent/bin` wraps `gh` for agents in Git Bash (`gh`) and PowerShell
  (`gh.ps1`): `gh` is never logged in, and each call reads a fine-grained token
  from `%USERPROFILE%\.config\gh-agent\token` (or `project-token` for
  `gh project`). The wrapper header documents the token setup.
- `scripts/update-skills.ps1` maintains shared Codex CLI and Claude Code skills
  from a separate, read-only checkout.

Windows Update, drivers, firmware, Store updates, services, registry tuning, and
automatic reboots are deliberately outside the update script's scope.

## Prerequisites

Before running the repository scripts, the machine needs:

- Native Windows 10 or Windows 11.
- PowerShell 7.0 or newer (`pwsh`). Windows PowerShell 5.1 is not supported.
- Internet access to GitHub and Scoop package sources during setup.
- Claude Code installed and available as `claude` for the pinned Claude plugins.
  Bootstrap checks this prerequisite before changing the machine; the existing
  native Claude installation is kept outside Scoop ownership.
- A standard, non-administrator PowerShell 7 terminal for Scoop and bootstrap.
- Windows Developer Mode enabled so the standard user can create symbolic links.
  Enabling it once requires administrator approval.
- An execution policy that permits local scripts. This setup uses `RemoteSigned`
  for the current user.

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
bootstrap. From a non-administrator PowerShell 7 terminal, install Scoop and Git
when they are not already available:

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

### 2. Clone the repository

```powershell
git clone --branch restructure/platform-folders https://github.com/boonyarit-iamsaard/dotfiles.git "$HOME\dotfiles"
Set-Location "$HOME\dotfiles\windows"
git branch --show-current
```

The branch command must print `restructure/platform-folders`, the branch that
holds the `windows/` folder until it reaches `main`. The repository is public,
so cloning does not require GitHub authentication. Authentication is required
only when pushing; Git Credential Manager can prompt for it on the first push.

Configure commit identity if a new Git installation does not have it yet. Write
it to `~\.gitconfig.local`, not `--global`: `~\.gitconfig` becomes a managed
link during bootstrap and bootstrap refuses to overwrite an existing file there.

```powershell
git config --file "$HOME\.gitconfig.local" user.name "Boonyarit Iamsa-ard"
git config --file "$HOME\.gitconfig.local" user.email "boonyarit.iamsaard@gmail.com"
```

If the machine already has an unmanaged `~\.gitconfig`, move it aside instead,
unless `~\.gitconfig.local` already exists (merge into it first):

```powershell
Move-Item -LiteralPath "$HOME\.gitconfig" -Destination "$HOME\.gitconfig.local"
```

### 3. Bootstrap

From the repository root:

```powershell
.\bootstrap.ps1
```

Bootstrap verifies the platform, PowerShell version, execution policy, and
Developer Mode before it installs declared packages, applies the user
environment, creates configuration links, clones or updates the skills checkout,
links agent skills, and runs the final verifier. It is safe to rerun after a
partial setup.

pnpm is provided by the Corepack shim bundled with the active NVM-managed Node
installation. Projects select their pnpm version through the `packageManager`
field; pnpm is intentionally not installed as a standalone Scoop package.

The environment manifest pins pnpm's store to `%LOCALAPPDATA%\pnpm\store` for
both pnpm 10 and 11. pnpm adds the versioned store subdirectory itself. An
explicit store prevents the automatic project-local fallback when a sandbox
cannot create hard links to the shared store. Agents use approved host execution
when sandbox access blocks a dependency operation.

The `git` link package also manages `~\.gitconfig` from `config/git/gitconfig`.
That file only includes `~/dotfiles/shared/gitconfig` (the shared essentials,
`core.symlinks=true`) and then `~/.gitconfig.local` for identity, signing, and
machine-only settings, so the checkout must live at `~\dotfiles`. Windows'
`http.sslBackend` stays in Git for Windows' system config, outside both files.
Use `git config --file "$HOME\.gitconfig.local" ...` for personal settings;
`--global` writes through the link into the tracked file. Verify with
`git config --global --includes --show-origin --get core.symlinks`, which must
name `shared/gitconfig`.

The package also installs `config/git/ignore` at Git's default global ignore
location, `%USERPROFILE%\.config\git\ignore`. It excludes `.pnpm-store/` from
untracked-file scans in every repository. A custom `core.excludesFile` or
`XDG_CONFIG_HOME` overrides that default location.

Apply these settings independently with:

```powershell
.\scripts\set-environment.ps1
.\scripts\link-dotfiles.ps1 git
pnpm store path
git check-ignore -v .pnpm-store/probe
```

Restart Codex, editors, and terminals after applying the environment so new
processes inherit the store settings. Editor watcher and search exclusions are
separate from Git ignores; configure `**/.pnpm-store/**` if an editor still
scans an existing accidental store.

NVM currently uses `link` mode as a workaround for the NVM4306 shim-mode false
positive tracked in nvm-windows issues
[#1379](https://github.com/nvm-windows/nvm/issues/1379) and
[#1403](https://github.com/nvm-windows/nvm/issues/1403). Link mode bypasses
NVM's delegated-script integrity check. Return `nvmMode` to `shim` in
`manifests/node-toolchain.json` once upstream resolves the false positive and
the verifier passes in shim mode.

## Verification

Bootstrap runs the verifier automatically. Run it independently at any time:

```powershell
.\scripts\verify-system.ps1
```

It checks:

- Windows and PowerShell prerequisites.
- The effective execution policy and Developer Mode.
- Git availability, and that the scripts run from the checkout's `windows`
  folder.
- Scoop availability and Scoop ownership of every declared package.
- Command availability for declared packages. Packages whose executable names
  differ from their Scoop names declare those commands in `packageCommands`.
- Managed user environment variables, existing managed directories, and
  prioritized, duplicate-free `PATH` entries.
- The declared NVM mode, active Node.js release, Corepack, and repository-pinned
  pnpm version.
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
  `dotfiles\shared\config\lazygit\config.yml`.

LazyGit layers the shared Default Dark Modern theme over this base through
`LG_CONFIG_FILE`, set by the PowerShell profile. Open a new PowerShell session
after relinking, or reload the profile with `. $PROFILE`.

Confirm idempotency by running bootstrap a second time. Existing packages and
correct links should be reported without being replaced.

## IdeaVim

The `ideavimrc` link package installs `shared/.ideavimrc` at
`%USERPROFILE%\.ideavimrc`, which the installed IntelliJ IdeaVim plugin reads:

```powershell
.\scripts\link-dotfiles.ps1 ideavimrc
```

An existing regular `.ideavimrc` must be preserved elsewhere before linking; the
linker refuses to overwrite unmanaged files.

## Themes

**Default Dark Modern** is active in Windows Terminal, Oh My Posh, LazyGit,
LazyDocker and btop. LazyGit, LazyDocker and btop use the shared theme variants.
Windows Terminal and Oh My Posh use the hand ports in their Windows folders.

| Theme               | Windows Terminal scheme | Oh My Posh                     | LazyGit variant in `shared/themes/lazygit/` | LazyDocker     |
| ------------------- | ----------------------- | ------------------------------ | ------------------------------------------- | -------------- |
| Default Dark Modern | Dark Modern (VS Code)   | `default-dark-modern.omp.json` | `default-dark-modern.yml` (active)          | active block   |
| Dark 2026           | Dark 2026               | `dark-2026.omp.json`           | `dark-2026.yml`                             | shared variant |
| Catppuccin Mocha    | Catppuccin Mocha        | `catppuccin-mocha.omp.json`    | `catppuccin-mocha.yml`                      | shared variant |

To switch:

- **Windows Terminal:** the linker installs each scheme in
  `config\windows-terminal` as a JSON fragment. Select it under **Settings >
  Defaults > Appearance > Color scheme**. Profile-level color scheme overrides
  need the same selection. The fragments leave the user-owned `settings.json`
  intact; a same-named scheme there takes precedence over a fragment.
- **Oh My Posh:** change `$ompTheme` in the PowerShell profile.
- **LazyGit:** change the theme variant filename in `LG_CONFIG_FILE` in the
  PowerShell profile, then reload it with `. $PROFILE`. Keep the shared base as
  the first file. The active Default Dark Modern variant is a shared hand port
  with upstream-verified colors; Dark 2026 is also available, vendored from the
  pinned upstream theme extra.
- **LazyDocker:** replace the block between the theme markers in
  `config\lazydocker\config.yml` with a variant from
  `../shared/themes/lazydocker/`, removing only its leading comment lines and
  blank lines. Update the opening marker's theme name too. LazyDocker has no
  include mechanism; the active block must match that shared variant.
- **btop:** the `btop` link package installs the shared Dark 2026, Default Dark
  Modern and Catppuccin Mocha themes in
  `%USERPROFILE%\scoop\persist\btop\themes`. Select one in btop's options, or
  set `color_theme` to `dark-2026`, `default-dark-modern` or `catppuccin-mocha`
  in that persistent directory's `btop.conf` while btop is closed. This native
  btop4win config remains runtime-owned; the older `config/btop/btop.conf` is
  not linked over it.

Sources:

- Dark 2026's five active tool themes match
  [dark-2026.nvim](https://github.com/boonyarit-iamsaard/dark-2026.nvim) at
  `4d19b8f1c1af75ae67d58506fb144e6b09d68e1f`, the shared theme pin. Windows
  Terminal's `extras/windows-terminal/dark-2026.json` and Oh My Posh's
  `extras/oh-my-posh/dark-2026.omp.json` are vendored byte for byte and exempt
  from formatting and line-ending conversion. Refresh them from that same pin
  when refreshing the shared extras; update the pin in
  `scripts/test-theme-extras.ps1` and run it to verify all five against upstream
  (requires Internet access). It also checks LazyDocker's active marker block.
  The upstream Terminal background is `#121314`; the prompt's PHP segment uses
  `symbol_field` (`#75beff`).
- Catppuccin Mocha's Windows Terminal scheme follows
  [catppuccin/windows-terminal](https://github.com/catppuccin/windows-terminal).
  Its shared btop and LazyGit files are vendored from the official ports at the
  commits in `shared/themes/catppuccin.json`; `scripts/test-theme-extras.ps1`
  checks them too.

## Dark Modern theme

`config\windows-terminal\dark-modern.json` adds **Dark Modern (VS Code)**, a
Windows Terminal port of VS Code's default dark theme. Colors are transcribed
from upstream
[`dark_modern.json`](https://github.com/microsoft/vscode/blob/main/extensions/theme-defaults/themes/dark_modern.json),
which `include`s `dark_plus.json` and `dark_vs.json`. A key absent from all
three falls back to VS Code's color registry default, as it does in the
integrated terminal. This follows the transcription approach of
[dark-2026.nvim](https://github.com/boonyarit-iamsaard/dark-2026.nvim).

Windows Terminal fragments are strict JSON, so provenance lives here:

| Scheme key            | Hex       | VS Code source                                                           |
| --------------------- | --------- | ------------------------------------------------------------------------ |
| `background`          | `#1f1f1f` | `editor.background` (theme)                                              |
| `foreground`          | `#cccccc` | `terminal.foreground` (theme)                                            |
| `cursorColor`         | `#cccccc` | `terminalCursor.foreground` is unset, so the terminal foreground         |
| `selectionBackground` | `#264f78` | `terminal.selectionBackground` → `editor.selectionBackground` (registry) |
| 16 ANSI colors        | see file  | `terminal.ansi*` (registry; the theme sets none)                         |

`background` uses `editor.background` rather than `panel.background`
(`#181818`), which VS Code paints behind its docked terminal. Here the terminal
is the whole window. The registry defaults are in
[`terminalColorRegistry.ts`](https://github.com/microsoft/vscode/blob/main/src/vs/workbench/contrib/terminal/common/terminalColorRegistry.ts)
and
[`editorColors.ts`](https://github.com/microsoft/vscode/blob/main/src/vs/platform/theme/common/colors/editorColors.ts).

Apply or check the managed theme links with:

```powershell
.\scripts\link-dotfiles.ps1 windows-terminal,lazygit,lazydocker,btop
.\scripts\verify-system.ps1
```

## LazyDocker

LazyDocker is installed through Scoop. Its themed configuration is tracked at
`config\lazydocker\config.yml` and linked to its native Windows config
directory:

```powershell
.\scripts\link-dotfiles.ps1 lazydocker
lazydocker
```

The config link is `%APPDATA%\lazydocker\config.yml`. A Docker daemon must be
reachable to use LazyDocker.

## Claude Code status line

The usage-focused status line is tracked at `config\claude\statusline.ps1` and
linked into `%USERPROFILE%\.claude`:

```powershell
.\scripts\link-dotfiles.ps1 claude
```

It shows the branch, model, effort, context usage, token count and session cost,
plus the 5-hour and 7-day rate limits on Pro and Max plans. It also publishes
each payload to `%USERPROFILE%\.claude\usage-input.json` for the Claude Usage
Monitor. Claude Code keeps plugin and session state in `settings.json`, so that
file is not linked; enable the status line there once:

```json
"statusLine": {
  "type": "command",
  "command": "pwsh -NoProfile -NonInteractive -File C:/Users/boony/.claude/statusline.ps1"
}
```

Test rendering changes with `.\scripts\test-statusline.ps1`.

## Shell configuration

The PowerShell 7 profile and its Oh My Posh themes are tracked in `powershell`
and linked into `%USERPROFILE%\Documents\PowerShell`:

```powershell
.\scripts\link-dotfiles.ps1 powershell
```

Oh My Posh uses `powershell\oh-my-posh\default-dark-modern.omp.json`; see
[Themes](#themes) for the alternatives. The Nerd Font Symbols preset also
remains available. Oh My Posh is declared in `manifests/packages.json`. One
dependency is not a Scoop package and is installed separately:

- `Terminal-Icons` comes from the PowerShell Gallery:
  `Install-Module Terminal-Icons -Scope CurrentUser`. The profile imports it
  only when it is present.

The user environment persists `ANDROID_HOME` and adds Platform Tools, Emulator,
and the latest Command-line Tools to `PATH`. It also keeps Temurin 25 as the
default JDK. Apply or check it independently with:

```powershell
.\scripts\set-environment.ps1
.\scripts\set-environment.ps1 -Check
```

The profile also provides:

- `jdk17` and `jdk25` to switch Java for the current PowerShell session. Use
  `jdk17` before React Native Android builds; Temurin 25 remains the default for
  other development.
- History-based command prediction in list view.
- `lzg` for lazygit and `lzd` for lazydocker.
- `check-manual-updates`, `docker-cleanup`, `link-dotfiles`, `set-environment`,
  `update-skills`, `update-system` and `verify-system` as aliases for the
  matching scripts in `scripts`, so they run from any directory. The profile
  finds the checkout through its own symlink target rather than a hard-coded
  path.

A nerd font is required for the prompt glyphs. The `nerd-fonts` bucket provides
them.

## Daily use

Format tracked JSON, JSONC, and Markdown files with the repository-pinned
Prettier version, from the checkout root (`..` from this folder):

```powershell
pnpm install --frozen-lockfile
pnpm format
pnpm format:check
```

The pnpm lockfile is generated and excluded from this formatting pass.

Update the declared developer environment:

```powershell
.\scripts\update-system.ps1
```

It finishes with a **Manual follow-up** summary. Nothing listed there is applied
automatically:

- `skills`: the upstream skills checkout is behind; run `update-skills`.
- `impeccable` or `ponytail`: a newer upstream release than the version pinned
  under `vendor` in `../shared/skills/skills.json`; refresh it with
  [docs/impeccable.md](docs/impeccable.md) or
  [docs/ponytail.md](docs/ponytail.md).

Run `check-manual-updates` alone for the same report without updating packages.
A source that cannot be reached shows `couldn't check` and does not fail the
update.

Remove all Docker containers, then prune unused volumes, networks, and builder
cache. Use `-WhatIf` to preview the destructive operations:

```powershell
docker-cleanup
docker-cleanup -WhatIf
```

Link or unlink one configuration package:

```powershell
.\scripts\link-dotfiles.ps1 lazygit
.\scripts\link-dotfiles.ps1 lazygit -Delete
.\scripts\link-dotfiles.ps1 lazydocker
.\scripts\link-dotfiles.ps1 lazydocker -Delete
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

The shared manifest at `../shared/skills/skills.json` declares the promoted
`engineering` and `productivity` buckets, personal skills, vendored payloads,
and pinned Claude plugins. Windows uses the `agents` and `claude` consumers; the
sync migrates the previous `codex` ownership records automatically. Personal
skills (`commit-message`, `typescript-house-style`, `edit-prose`, `runbook`) and
vendored Impeccable and Ponytail live under `../shared/skills/`.

Claude receives Ponytail through its pinned plugin, including the session hook
and slash commands. The sync removes its old managed Ponytail skill links so
Claude loads one copy. The `agents` consumer keeps the vendored skills.
`-DryRun` and `-Check` inspect plugin state without changing it; a normal sync
installs and enables the manifest's pin. It requires the existing `claude` CLI
on `PATH`, as listed in the bootstrap prerequisites.

The shared `edit-prose/rules.md` link reads the `humanizer` checkout next to
dotfiles at `../workspace/personal/humanizer`. A first sync without `-NoPull`
clones it when missing. Existing files are preserved, and `-Check` or `-NoPull`
reports a missing dependency with the clone location. Existing humanizer
checkouts are left at their current revision.

Impeccable also supplies Claude subagents. They are linked individually through
`manifests\links.json`, leaving `$HOME\.claude\agents` as a real directory. See
[Impeccable maintenance](docs/impeccable.md) for provenance, updates, hooks, and
verification.

## Manifests

- `manifests/packages.json` declares Scoop buckets and developer packages.
- `manifests/environment.json` declares managed user environment variables and
  prioritized `PATH` entries.
- `manifests/node-toolchain.json` declares the Node.js release and NVM mode.
- `manifests/links.json` maps tracked files to native Windows destinations.
- `../shared/skills/skills.json` declares the skills fork, promoted categories,
  consumers, personal and vendored skills, and pinned Claude plugins. The fork
  checkout defaults to `$HOME\skills`; `SKILLS_REPO` overrides it for the sync.

Add future tools through these manifests so bootstrap, update, and verification
continue to share one source of truth.

## Machine notes

- **Git is system-wide:** Git is installed under `C:\Program Files\Git`, not by
  Scoop. Do not add a second Git without first reviewing `PATH` precedence.
- **Git TLS backend:** this checkout sets `http.sslBackend=openssl` in its local
  Git config because Schannel failed in the automation environment. Check it
  with `git config --local --get http.sslBackend`.

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
- **Wrong folder:** run setup and verification from `$HOME\dotfiles\windows`.
