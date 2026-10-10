# Global agent environment

- For native Windows machine setup or persistent developer-tool changes, read
  `C:\Users\boony\dotfiles\README.md` and the relevant manifests and scripts
  before acting. Treat that repository as the source of truth.
- Run PowerShell commands and scripts with PowerShell 7 or newer (`pwsh`), not
  Windows PowerShell 5.1.
- Before pnpm dependency installs or updates, confirm `pnpm store path` resolves
  under the shared store configured by dotfiles. If it resolves inside the
  project or sandbox access fails, use approved host execution with the
  configured shared store. Preserve this store location rather than creating a
  project-local store to bypass sandbox restrictions.
