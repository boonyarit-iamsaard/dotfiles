# Dotfiles agent guide

One checkout holds every platform's setup in its own folder. Work inside the
folder for the platform you are changing and follow its guide:

| Folder     | Platform       | Guide                                  |
| ---------- | -------------- | -------------------------------------- |
| `windows/` | Native Windows | [windows/AGENTS.md](windows/AGENTS.md) |

`macos/` and `wsl/` are being brought in; until then their setup lives on the
`main` and `wsl` branches. The migration plan is the spec in
`.scratch/platform-consolidation/`.

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
- `.scratch/` is ignored. Track a file there only for research, issues and
  tickets, or when the owner says so or agrees when asked; add it with
  `git add -f`.

## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature>/`. See
`docs/agents/issue-tracker.md`.

### Triage labels

The five default triage roles, each label string equal to its role name. See
`docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See
`docs/agents/domain.md`.
