# Windows dotfiles handoff

Read `AGENTS.md` before making changes. This handoff describes the state at the
end of the initial native Windows setup session.

## Goal and decisions

- This repository uses permanent, independent platform branches that are never
  merged:
  - `main` is macOS.
  - `wsl` is WSL.
  - `windows` is native Windows.
- The Windows branch is intended for native mobile and general development.
- Scoop is the only package manager used by automated setup and updates. Do not
  add Winget fallback.
- PowerShell is the stage-zero bootstrap language because it is present on a
  reset Windows machine. Python may be installed and used later, but bootstrap
  must not depend on it.
- `scripts/update-system.ps1` is developer-scoped. It must not automate Windows
  Update, Store updates, drivers, firmware, services, registry tuning, or
  reboots.
- Windows dotfiles use explicit source-to-destination mappings and symbolic
  links as the native equivalent of GNU Stow.

## Git and checkout state

- Checkout: `C:\Users\boony\dotfiles`
- Current branch: `windows`
- Upstream: `origin/windows`
- The local fetch refspec was corrected from the original single-branch `wsl`
  rule to `windows`.
- Remote `origin/windows` exists at the same base commit as `wsl` (`0c5ebe7`)
  before the work in this handoff.
- Git identity is configured globally as:
  - `Boonyarit Iamsa-ard`
  - `boonyarit.iamsaard@gmail.com`
- Git Credential Manager is configured by the system Git installation.
- This checkout uses local `http.sslBackend=openssl` because Schannel failed in
  the automation environment.
- Git is currently installed system-wide under `C:\Program Files\Git`, not by
  Scoop. Fresh-machine documentation installs Git through Scoop. Decide later
  whether to migrate this existing machine; do not install a second Git copy
  without reviewing PATH precedence.

## Machine state

- PowerShell execution policy is `RemoteSigned` for the current user.
- Windows Developer Mode is enabled.
- Scoop is installed and working.
- Configured Scoop buckets observed during setup: `main`, `extras`, and
  `nerd-fonts`.
- Lazygit `0.64.1` is installed from Scoop `extras`.
- Lazygit config link:
  - Destination: `C:\Users\boony\AppData\Local\lazygit\config.yml`
  - Source: `C:\Users\boony\dotfiles\config\lazygit\config.yml`
- The temporary user-level `LG_CONFIG_FILE` environment variable was removed;
  lazygit now uses its normal Windows config directory and follows the link.

## Repository work completed but not committed

- Replaced the WSL-oriented `README.md` with a Windows setup, prerequisite,
  verification, and troubleshooting guide.
- Added `AGENTS.md` with Windows-only scope and agent verification rules.
- Added `bootstrap.ps1` as the fresh-machine entrypoint.
- Added `manifests/packages.json`; it currently declares only the `extras`
  bucket and `lazygit` package.
- Added `manifests/links.json`; it currently maps only lazygit.
- Added `scripts/install-packages.ps1`.
- Added `scripts/link-dotfiles.ps1`.
- Added `scripts/update-system.ps1`.
- Added `scripts/verify-system.ps1`.
- Added this `HANDOFF.md`.

Run `git status --short` before continuing. All work above is intentionally
uncommitted so it can be reviewed together.

## Behavior implemented

### Bootstrap

`bootstrap.ps1`:

1. Requires native Windows and PowerShell 7.0 or newer.
2. Ensures a script-compatible execution policy.
3. Requires Developer Mode before attempting managed links.
4. Installs Scoop only when it is absent.
5. Installs manifest-declared packages.
6. Creates manifest-declared links.
7. Runs the verifier.

### Package updates

`scripts/update-system.ps1` refreshes Scoop metadata, then updates and cleans
only packages listed in `manifests/packages.json`. It deliberately does not run
`scoop update *` or `scoop cleanup *`.

### Links

`scripts/link-dotfiles.ps1`:

- Is idempotent.
- Refuses to overwrite or delete an unmanaged target.
- Supports unlinking with `-Delete`.
- Uses the Windows `CreateSymbolicLinkW` API with the unprivileged-creation flag
  for consistent standard-user symbolic link creation.

The existing lazygit link was initially created with native `mklink` after
Developer Mode was enabled. The updated linker has been tested against that
existing link for idempotency. Its fresh-link API path has not been tested by
removing the working lazygit link; do not destroy the working link merely to
test it. Prefer adding a disposable test fixture or injectable manifest path.

## Verification already performed

- `scripts/update-system.ps1` completed successfully and touched only Scoop
  metadata plus the manifest-declared lazygit package.
- A complete second run of `bootstrap.ps1` succeeded:

  ```text
  Already installed: lazygit
  Already linked lazygit: C:\Users\boony\AppData\Local\lazygit\config.yml
  Developer environment verification passed.
  Windows developer environment bootstrap complete.
  ```

- `scripts/verify-system.ps1` passed in the real Windows user environment.
- All PowerShell files parsed successfully with PowerShell's language parser.
- Both JSON manifests parsed successfully with `ConvertFrom-Json`.
- `git diff --check` passed.

Repeat the documented validation after further changes:

```powershell
.\scripts\verify-system.ps1
git diff --check
git status --short --branch
```

## Known remaining work

1. Review the complete uncommitted diff before committing.
2. Consider adding a disposable test path for fresh symlink creation without
   disturbing the live lazygit link.
3. Add developer packages gradually through `manifests/packages.json`; preserve
   the Scoop-only policy.
4. Add config mappings through `manifests/links.json` and keep the linker safe
   around pre-existing files.
5. Decide whether this machine's system Git should eventually be replaced by
   Scoop Git.
6. Continue reviewing inherited WSL-only files outside agent skill management.
   The obsolete Stow skill packages and POSIX skills updater were replaced with
   a native Windows implementation after comparison with the macOS branch.
7. Commit and push only after review. No commit was created in this session.

## Agent skill maintenance added

- The user's fork is cloned beside dotfiles at `C:\Users\boony\skills`.
- `manifests/skills.json` declares the fork, promoted categories, Codex and
  Claude destinations, and locally owned skills.
- `scripts/update-skills.ps1` performs clean fast-forward pulls and safe,
  per-skill reconciliation without GNU Stow.
- Migration verifies copied upstream files against Git history, snapshots and
  archives accepted copies, refuses modified collisions, and rolls back failed
  link creation.
- `scripts/test-update-skills.ps1` exercises migration, idempotency, collision
  refusal, and stale-link cleanup in a disposable fixture.
- The personal `commit-message` and `typescript-house-style` skills are stored
  once under `skills\shared` and linked into both consumers.
