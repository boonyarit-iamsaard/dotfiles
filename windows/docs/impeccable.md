# Impeccable maintenance

Impeccable is vendored in this repository so the dotfiles manifests remain the
only owners of user-wide agent files. The upstream global installer must not
write directly to `$HOME\.agents\skills` or `$HOME\.claude\skills`.

## Layout and ownership

- `skills\vendor\impeccable\codex` contains the Codex skill, including its
  nested Codex agent definitions.
- `skills\vendor\impeccable\claude` contains the Claude Code skill.
- `skills\vendor\impeccable\claude-agents` contains Claude Code's separate
  subagent definitions.
- `manifests\skills.json` links the provider-specific skill folders into the two
  user-wide skill roots.
- `manifests\links.json` links each Claude subagent file into the existing
  `$HOME\.claude\agents` directory.

The vendored payload was generated on 2026-09-09 with:

```powershell
npx --yes impeccable@4.0.4 install -y `
  --providers=claude,codex `
  --scope=project `
  --no-hooks
```

The resulting skill metadata reports Impeccable 4.3.0 and its launcher pins
engine 0.1.5. The platform binary and runtime cache are intentionally omitted:
the checked-in launcher downloads the pinned, checksum-verified engine into
`$HOME\.impeccable\bin` on first use.

Impeccable is redistributed under Apache 2.0. Keep
`skills\vendor\impeccable\LICENSE` with every vendored refresh.

## Install and verify

Run the normal reconcilers from the dotfiles root:

```powershell
.\scripts\update-skills.ps1 -NoPull
.\scripts\link-dotfiles.ps1 impeccable
```

Restart Codex and Claude Code after the first install. In Codex, invoke the
skill as `$impeccable`; in Claude Code, invoke it as `/impeccable`.

## Refresh the vendored payload

Treat a refresh as a reviewed dependency update:

1. Start from a clean dotfiles worktree and create an empty staging directory
   outside it.
2. Run the installer command above from the staging directory, changing the npm
   version only when intentionally upgrading.
3. Replace the three owned vendor payloads from `.agents\skills\impeccable`,
   `.claude\skills\impeccable`, and `.claude\agents\impeccable-*.md`.
4. Omit `scripts\bin` and `scripts\.impeccable`; they contain a platform binary
   and runtime state rather than portable skill source.
5. Review the complete diff, including `SKILL.md`, scripts, references, agent
   permissions, and reported versions.
6. Preserve upstream formatting under `skills\vendor`; `.prettierignore` keeps
   dependency refreshes reviewable.
7. Run the verification sequence below before committing.

Use the dotfiles reconcilers after the vendor copy. Running
`npx impeccable update` from a home directory would bypass manifest ownership
and can collide with the managed links.

## Hooks and project state

The user-wide skill does not install Impeccable's automatic design hook. The
upstream Codex hook invokes a project-relative `.agents\skills\impeccable`
launcher, while this repository provides a user-wide skill. Keep hooks an
explicit project decision; review and approve a project's hook separately.

Impeccable may create product-owned `PRODUCT.md`, `DESIGN.md`, and selected
`.impeccable` files inside a project. Those belong to that project, not this
dotfiles repository. Follow Impeccable's generated ignore guidance for runtime
caches and screenshots.

## Verification

```powershell
.\scripts\test-update-skills.ps1
.\scripts\update-skills.ps1 -Check -NoPull
.\scripts\link-dotfiles.ps1 impeccable
.\scripts\link-dotfiles.ps1 impeccable
.\scripts\verify-system.ps1
pnpm install --frozen-lockfile
pnpm format:check
git diff --check
```

The second link command must report every Claude agent as already linked. A
collision is an ownership question: inspect it and migrate it deliberately;
never force the installer over an existing path.
