# Windows dotfiles agent guide

This branch configures a native Windows developer environment. Do not add
macOS, Linux, or WSL setup to this branch.

## Canonical workflow

- `bootstrap.ps1` is the fresh-machine entrypoint.
- `manifests/packages.json` is the source of truth for Scoop buckets and
  developer packages.
- `manifests/links.json` is the source of truth for managed config links.
- `manifests/skills.json` is the source of truth for shared and local agent
  skills.
- `scripts/update-system.ps1` updates only developer packages declared in the
  manifest.
- `scripts/update-skills.ps1` updates skills only when invoked directly; do not
  call it from `scripts/update-system.ps1`.
- `scripts/verify-system.ps1` must pass after setup changes.

## Prerequisites

- Native Windows with PowerShell 7.0 or newer (`pwsh`).
- A non-administrator PowerShell terminal for Scoop and bootstrap operations.
- `RemoteSigned`, `Unrestricted`, or `Bypass` as the effective execution policy.
- Windows Developer Mode enabled for unprivileged symbolic links.
- Internet access to GitHub and Scoop sources during installation and updates.
- Git is required to clone this repository; the README contains the pre-clone
  Scoop setup.

## Constraints

- Use Scoop. Do not add Winget fallback or `winget upgrade --all`.
- Do not automate Windows Update, drivers, services, firmware, Store updates,
  registry tuning, or reboots in `update-system.ps1`.
- Keep all scripts safe to run repeatedly.
- Never overwrite or remove an unmanaged user file. Stop with a clear error.
- Prefer native PowerShell for bootstrap, package, environment, registry, and
  symlink operations. Python may be used after bootstrap only when it provides
  a clear advantage.
- Add packages and links through their manifests instead of one-off setup code.
- Keep skill destination roots as real directories and link individual skills.
- Never replace a copied or same-name skill unless migration proves its files
  came from the configured source history or exactly match a local source.

## Required verification

After changing bootstrap, manifests, linking, or update behavior:

1. Parse every `.ps1` file with PowerShell's language parser.
2. Parse every JSON manifest with `ConvertFrom-Json`.
3. Run `git diff --check`.
4. Run `scripts/verify-system.ps1` in a normal user PowerShell session.
5. For link changes, run `scripts/link-dotfiles.ps1 <package>` twice and confirm
   the second run reports that the package is already linked.
6. For skill changes, run `scripts/test-update-skills.ps1`, then run
   `scripts/update-skills.ps1 -Check -NoPull` after the live links are set up.

Do not delete and recreate a working user link merely to test setup. Do not run
the updater unless the user authorized package updates in the current task.
