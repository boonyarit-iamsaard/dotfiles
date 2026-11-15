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

- **Platform work runs on its own machine.** Change a platform folder only on
  that platform's machine, where its live links and tools can be verified. A
  problem seen in another platform's folder becomes a ticket in the issue
  tracker, not an edit. This is a hard rule.
- **Root files belong to every platform** and may be fixed from any machine.
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
