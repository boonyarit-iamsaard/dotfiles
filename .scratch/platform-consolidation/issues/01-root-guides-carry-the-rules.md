# 01: Root guides carry the rules

**What to build:** The root guides replace the handoff. An agent opening the repo
on any machine learns the lasting rules from the root agent guide: one folder
per platform, repository tooling at the root, root files belong to every
platform, platform-specific work runs only on that platform's machine (other
platforms get tickets here), `CLAUDE.md` files are symlinks to their
`AGENTS.md`, and `.scratch/` is tracked only for research, issues and tickets or
when the owner says so. The root README points to the platform folders and to
this spec. The handoff is removed, and stale root leftovers from the Windows
move are fixed (the `.gitignore` comment naming the old font-patcher path, the
`windows-dotfiles` package name). The spec and tickets are committed with
`git add -f`.

**Blocked by:** None (can start immediately).

**Where:** Any machine; root files only.

**Status:** done

- [x] The handoff file is gone and nothing at the root links to it
- [x] The root agent guide states every rule listed above
- [x] The root README names the spec as the migration plan
- [x] No root file refers to pre-move paths; the package name is platform-neutral
- [x] Spec and tickets are tracked on the integration branch
- [x] `pnpm format:check` and `git diff --check` pass at the root
