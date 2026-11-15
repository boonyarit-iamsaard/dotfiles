# Dotfiles agent guide

One checkout holds every platform's setup in its own folder. Work inside the
folder for the platform you are changing and follow its guide:

| Folder     | Platform       | Guide                                  |
| ---------- | -------------- | -------------------------------------- |
| `windows/` | Native Windows | [windows/AGENTS.md](windows/AGENTS.md) |
| `macos/`   | macOS          | [macos/README.md](macos/README.md)     |
| `wsl/`     | WSL            | [wsl/README.md](wsl/README.md)         |

`macos/` and `wsl/` have no agent guide of their own yet; follow their README.
The WSL files are in `wsl/`, but the WSL machine still runs from the `wsl`
branch until its setup is pointed at this folder. The migration plan is issue
#14 and its sub-issues.

## Repository-wide rules

- **Behavior changes are made and verified on their platform.** A behavior
  change touches anything a platform reads or runs: config, scripts and their
  executable bits, link lists, manifests, Stow layout, and lint fixes in any of
  these, even whitespace or comments alone. A platform is the environment the
  session runs in (macOS, Windows, WSL), not the hardware. A behavior change
  needed on another platform becomes an issue, not an edit. This is a hard rule.
- **Root and `shared/` behavior changes are verified on every platform they
  affect.** Make the change on one affected platform and verify it there; it is
  done when each affected platform has verified it, one checkbox per platform in
  its issue.
- **Inert changes may be made from any machine.** An inert change leaves every
  platform's behavior as it was: documentation, lint configuration, lint fixes
  in documentation, and formatting. Formatting is only what the root formatter
  writes (`pnpm format`): `pnpm format:check` passes and
  `git diff --ignore-all-space` shows nothing beyond rewrapped lines. Check a
  doc that describes live state against the files in the repo.
- Keep platform-specific setup inside its platform folder. Never add one
  platform's setup to another's folder.
- Repository tooling lives at the root: `package.json` (Prettier and the pinned
  pnpm), `.prettierrc.json`, `.prettierignore`, `.gitattributes`, and
  `.gitignore`.
- After changing JSON, JSONC, or Markdown, run `pnpm install --frozen-lockfile`
  and `pnpm format:check` from the root, then `git diff --check`.
- Vendored third-party payloads keep their upstream bytes; `.gitattributes` and
  `.prettierignore` exempt them.
- `CLAUDE.md` files are symlinks to the `AGENTS.md` beside them. Edit
  `AGENTS.md`.
- `.scratch/` is ignored. Track a file there only for research, or when the
  owner says so or agrees when asked; add it with `git add -f`.

## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues; specs are parent issues with their
tickets as sub-issues. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default triage roles, each label string equal to its role name. See
`docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See
`docs/agents/domain.md`.
