# Dotfiles agent guide

One checkout holds every platform's setup in its own folder. Work inside the
folder for the platform you are changing and follow its guide:

| Folder     | Platform       | Guide                                  |
| ---------- | -------------- | -------------------------------------- |
| `windows/` | Native Windows | [windows/AGENTS.md](windows/AGENTS.md) |

`wsl/` and `macos/` are planned; their setup still lives on the `wsl` and `main`
branches until each is moved on its own machine. See [HANDOFF.md](HANDOFF.md).

## Repository-wide rules

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
- `.scratch/` is ignored. Track a file there only deliberately, with
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
