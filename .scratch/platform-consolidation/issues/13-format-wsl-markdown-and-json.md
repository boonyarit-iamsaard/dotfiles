# 13: WSL Markdown and JSON pass the root format check

**What to build:** `pnpm format:check` at the root passes for `wsl/`. The
rebuild (ticket 06) brought `wsl/` under the root Prettier check, and 17 of its
files were never formatted to it. Hand-written files are formatted with
`pnpm format`. Files that a tool writes or that come from upstream are left as
they are and added to the root `.prettierignore` instead, so a tool or upstream
refresh does not fight the formatter. Likely candidates: `lazy-lock.json` and
`lazyvim.json` (written by lazy.nvim and LazyVim), and skill files synced from
upstream by the WSL skill sync, such as `edit-prose/CREDITS.md`.

Files that fail today, as `wsl/` paths:

- `agents/.agents/skills/README.md`
- `agents/.agents/skills/commit-message/SKILL.md`
- `agents/.agents/skills/typescript-house-style/SKILL.md`
- `claude/.claude/agents/general-purpose.md`
- `claude/.claude/skills/README.md`
- `claude/.claude/skills/commit-message/SKILL.md`
- `claude/.claude/skills/edit-prose/CREDITS.md`
- `claude/.claude/skills/edit-prose/SKILL.md`
- `claude/.claude/skills/runbook/SKILL.md`
- `claude/.claude/skills/runbook/template.md`
- `claude/.claude/skills/typescript-house-style/SKILL.md`
- `config/nvim/README.md`
- `config/nvim/lazy-lock.json`
- `config/nvim/lazyvim.json`
- `docs/adr/0001-palette-owned-upstream-extras-vendored.md`
- `GLOSSARY.md`
- `README.md`

`GLOSSARY.md` and `docs/adr/` move to the root in ticket 07; format them where
they land.

**Blocked by:** 07

**Where:** WSL machine only. The skill sync and Neovim must be checked after
formatting, and both run there.

**Status:** ready-for-agent

- [ ] `pnpm format:check` passes for every file under `wsl/`
- [ ] Each file is either formatted or listed in `.prettierignore`, with the reason in a comment
- [ ] The WSL skill sync check still reports up to date
- [ ] Neovim starts and `lazy-lock.json` is unchanged after a sync
- [ ] `git diff --check` passes
- [ ] Pushed to the integration branch
