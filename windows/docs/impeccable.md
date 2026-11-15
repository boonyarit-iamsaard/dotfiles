# Impeccable maintenance

Impeccable's provider builds live in `../../shared/skills/vendor/impeccable`,
with the npm pin in `../../shared/skills/skills.json`. Windows reads that
manifest for skills and `manifests/links.json` for the four Claude agent files.
The skill roots and `$HOME\.claude\agents` stay real directories; individual
skills and agent files are linked into them.

See [the shared guide](../../shared/skills/README.md#refresh-a-vendored-payload)
for payload refreshes, licensing, executable permissions, and engine
provisioning. A refresh affects every platform and needs verification on each.
Keep upstream bytes and omit runtime caches and platform binaries. Never run the
upstream global installer over managed links.

## Install and verify

Run from `windows/`:

```powershell
.\scripts\update-skills.ps1 -NoPull
.\scripts\link-dotfiles.ps1 impeccable
.\scripts\link-dotfiles.ps1 impeccable
.\scripts\test-update-skills.ps1
.\scripts\update-skills.ps1 -Check -NoPull
.\scripts\verify-system.ps1
```

The second link command reports each Claude agent as already linked. A collision
requires inspecting ownership; the linker preserves unmanaged files.

On native Windows, provision and check both engines from the repository root:

```powershell
.\shared\skills\vendor\impeccable\codex\scripts\impeccable.cmd engine-probe
.\shared\skills\vendor\impeccable\claude\scripts\impeccable.cmd engine-probe
```

The launchers download their pinned engine on first use and verify its checksum.
Restart Codex and Claude Code after installation, then invoke `$impeccable` in
Codex or `/impeccable` in Claude Code.

## Hooks and project state

The sync installs the skill without changing Impeccable hooks. Automatic design
hooks remain an explicit project decision. Impeccable's project-owned
`PRODUCT.md`, `DESIGN.md`, and `.impeccable` state belong to that project;
follow its generated ignore guidance for caches and screenshots.
