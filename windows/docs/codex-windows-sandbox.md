# Codex on native Windows

Researched 2026-11-22 using Codex CLI 0.171.0 on Windows build 10.0.26200.0.

The best-supported fix for PowerShell 7 in the native sandbox is a machine-wide
PowerShell 7.6 LTS MSI and a fresh Codex session. Keep approved host execution
for Git metadata writes and for dependency operations that need the shared pnpm
store. The local MXC startup test passed, which makes MXC a viable option to
test separately. [PowerShell installation][ps-install], [Windows sandbox
guide][windows].

## Why the sandbox runs PowerShell 5.1

Before installing the MSI, `exec_command` with `shell` set to `pwsh` or the
absolute Store executable path ran Windows PowerShell 5.1 under
`workspace-write` with the elevated Windows backend. An approved
`require_escalated` call ran Store PowerShell 7.7.0. The host resolved
`pwsh.exe` through Microsoft Store paths and had no
`C:\Program Files\PowerShell\7\pwsh.exe`.

Codex 0.171.0 uses the `shell` argument to select a shell family, then discovers
the executable. For local sandboxed commands, both `elevated` and `mxc` can
replace the Store binary or its WindowsApps alias. The resolver tries a
sandbox-compatible `pwsh` first, including the standard machine-wide path, then
`powershell.exe`. Elevated mode also supplies `-NoProfile`. The rewrite leaves
approved host attempts and `unelevated` commands as originally resolved. This
matches the local 5.1 fallback and explains why an absolute `shell` argument had
the same result. [0.171.0 shell lookup][shell-source], [0.171.0 runtime
logic][runtime-source].

Two independent Desktop reports compared the same command before and after
installing the MSI and restarting Codex. One saw Windows error 5 with Store
PowerShell, then PowerShell 7 in the elevated sandbox. The other saw error 1312,
then working 5.1 after disabling the App Execution Alias, then PowerShell 7
after installing the MSI. A separate report found that disabling the alias alone
left the direct Store package directory ahead of MSI PowerShell on the process
`PATH`. A controlled `unelevated` test also worked with the MSI and failed with
the Store alias. [Desktop MSI test][msi-test], [alias and MSI test][alias-test],
[PATH precedence report][path-test], [unelevated test][unelevated-test].

For this machine, use Microsoft's PowerShell 7.6.10 x64 MSI. A local WinGet
lookup for `Microsoft.PowerShell` with `--installer-type wix` selected 7.7.0 and
found no installer. Adding `--version 7.6.10.0` returned the linked x64 MSI.
Microsoft documents that plain WinGet installation defaults to MSIX starting
with 7.6.0 and that 7.7.0 has no MSI. After installing, fully restart Codex and
confirm the actual PowerShell host in both ordinary sandboxed and approved host
calls. Use `$PSVersionTable.PSVersion`, `(Get-Process -Id $PID).Path`, and, to
inspect candidates, `Get-Command pwsh.exe -All`. If WindowsApps still wins,
check the Codex process's `PATH` and the app alias. Use explicitly selected
`cmd.exe` for simple reads or a focused startup probe, and approved host `pwsh`
when a PowerShell 7 script is required before the sandbox shell is working. The
local dotfiles Windows README treats PowerShell 7 as a bootstrap prerequisite.
[Windows dotfiles setup][dotfiles-windows], [Microsoft installation
guide][ps-install], [PowerShell 7.6.10 assets][ps-release], [x64 MSI][ps-msi].

## Git and pnpm

- **Git metadata.** The standard workspace policy protects `.git` and the Git
  directory resolved from a linked worktree's `.git` pointer. Users report
  `index.lock` and ref lock failures despite ordinary source edits working.
  Staging and commits succeeded for one reporter in regular Windows PowerShell,
  and another reported stable Git operation through approved `require_escalated`
  calls. An approved host call created a task branch successfully during this
  investigation. Follow the repository host-command guidance for branch changes,
  staging, and commits when the sandbox blocks them. A report involving a
  filesystem deny rule and a linked worktree still saw failures after approval.
  [Protected workspace paths][protected-paths], [Git permission
  reports][git-deny], [verified host workflow][git-host], [linked-worktree
  report][git-worktree].
- **pnpm tools and store.** The dotfiles Windows README and
  `windows/manifests/environment.json` pin the store under
  `%LOCALAPPDATA%\pnpm\store` and delegate pnpm version selection to the
  NVM-managed Corepack shim and the project's `packageManager` field. The host
  `pnpm store path` resolved to the expected `v11` subdirectory. Before an
  install or update, check the actual `pnpm` executable, version, and store
  path. If the store is inaccessible or resolves inside the project, use
  approved host execution with the configured shared store. One Windows Desktop
  report traced an `EPERM` to a pnpm hardlink with different file and parent
  ACLs. The same file was readable on the host. Another report identified a
  bundled pnpm shim taking precedence and suggested selecting the intended
  Corepack binary explicitly when versions differ. A host install may still
  leave a hardlinked file inaccessible to a sandboxed test, so verify a direct
  read before diagnosing pnpm itself. [Dotfiles environment
  manifest][dotfiles-env], [pnpm store behavior][pnpm-store], [Windows hardlink
  comparison][pnpm-acl], [bundled shim report][pnpm-shim].

## Backend and permission choices

- **MXC.** OpenAI recommends Microsoft Execution Containers where the host and
  policy support them. MXC uses native isolation in the user's environment
  without separate Windows accounts or administrator-approved setup. Consumer
  Desktop prefers it automatically on compatible devices. CLI users can use
  `features.prefer_mxc = true` for automatic selection with a legacy fallback.
  This host returned `MXC_OK` and exit 0 from the documented one-command probe
  with `--include-managed-config`, `--permission-profile ':workspace'`, and
  `cmd.exe /d /c echo MXC_OK`. That verifies command startup for that probe.
  Agent PowerShell, Git, and pnpm behavior in MXC remain untested here. [MXC
  compatibility probe][mxc], [OpenAI sandbox engineering notes][engineering].
- **Legacy backends.** `elevated` requires administrator approval during setup
  and runs commands as dedicated restricted users. `unelevated` uses a
  restricted token for the current Windows user, offers weaker network
  isolation, and lacks denied-read support. The Store alias failures reported
  under `unelevated` make it a poor choice for resolving the PowerShell symptom
  alone. OpenAI recommends WSL for Linux-native workflows or if the available
  Windows backends fall short. A WSL trial fits best with a separate clone under
  the Linux home directory and its own toolchain. [Windows sandbox
  guide][windows], [legacy sandbox design][legacy], [unelevated
  test][unelevated-test], [WSL guide][wsl].
- **Permission profiles and approvals.** The backend enforces the active
  permission profile. Use `:workspace` for ordinary project work and consider a
  named profile extending it only for a recurring, specific path that policy
  permits. Configure `default_permissions` separately from the legacy
  `sandbox_mode` settings. Auto-review handles eligible requests under the
  configured approval policy. For recurring host operations, a narrow command
  rule can prompt on a specific prefix, with managed policy still applying. A
  host approval uses the host account's existing privileges. Full access removes
  the workspace filesystem boundary across commands, and the first report of the
  shell issue also experienced failures in that mode. [Configuration
  reference][config], [approvals guide][approvals], [command rules][rules],
  [original shell issue][shell-issue].

## MCP launchers after the Desktop update

The local `node_repl` user configuration and cached `cua_repl` plugin launcher
both referenced the missing Codex MSIX package `26.1111.2228.0`. The installed
package `26.1117.4957.0` contained the required binaries and script. Both paths
were updated after backing up the two files. A fresh app-server process reported
both MCP servers initialized and advertising tools through
`mcpServerStatus/list`. Verification covered that fresh process.

[windows]: https://learn.chatgpt.com/docs/windows/windows-sandbox
[mxc]: https://learn.chatgpt.com/docs/windows/windows-sandbox#mxc-compatibility
[engineering]: https://openai.com/index/inside-the-codex-sandbox/
[legacy]: https://openai.com/index/building-codex-windows-sandbox/
[wsl]: https://learn.chatgpt.com/docs/windows/wsl#work-on-code-inside-wsl
[config]: https://learn.chatgpt.com/docs/config-file/config-reference
[approvals]:
  https://learn.chatgpt.com/docs/agent-approvals-security#automatic-approval-reviews
[protected-paths]:
  https://learn.chatgpt.com/docs/agent-approvals-security#protected-paths-in-writable-roots
[rules]: https://learn.chatgpt.com/docs/agent-configuration/rules
[shell-source]:
  https://github.com/openai/codex/blob/rust-v0.171.0/codex-rs/shell-command/src/shell_detect.rs#L243-L321
[runtime-source]:
  https://github.com/openai/codex/blob/rust-v0.171.0/codex-rs/core/src/tools/runtimes/mod.rs#L131-L186
[ps-install]:
  https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.6#install-powershell-using-winget
[ps-release]: https://github.com/PowerShell/PowerShell/releases/tag/v7.6.10
[ps-msi]:
  https://github.com/PowerShell/PowerShell/releases/download/v7.6.10/PowerShell-7.6.10-win-x64.msi
[msi-test]: https://github.com/openai/codex/issues/35871#issuecomment-5199532611
[alias-test]:
  https://github.com/openai/codex/issues/18937#issuecomment-5263280816
[path-test]:
  https://github.com/openai/codex/issues/35871#issuecomment-5437819139
[unelevated-test]:
  https://github.com/openai/codex/issues/35871#issuecomment-5909610658
[shell-issue]: https://github.com/openai/codex/issues/18937
[git-deny]: https://github.com/openai/codex/issues/18918
[git-host]: https://github.com/openai/codex/issues/37965#issuecomment-5849439088
[git-worktree]:
  https://github.com/openai/codex/issues/32880#issuecomment-5856962132
[pnpm-store]:
  https://pnpm.io/faq#does-pnpm-work-across-multiple-drives-or-filesystems
[pnpm-acl]: https://github.com/openai/codex/issues/45958
[pnpm-shim]:
  https://github.com/openai/codex/issues/30440#issuecomment-5330604383
[dotfiles-windows]: ../README.md#1-prepare-powershell-7-scoop-and-git
[dotfiles-env]: ../manifests/environment.json
