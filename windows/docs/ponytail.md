# Ponytail maintenance

[Ponytail](https://github.com/DietrichGebert/ponytail) is vendored for the
`agents` consumer and installed as a pinned Claude plugin, following
[ADR 0002](../../docs/adr/0002-skills-shared-from-one-manifest.md).

The shared manifest at `../../shared/skills/skills.json` records both the
vendored commit and Claude marketplace ref. Keep them equal when refreshing; the
payload refresh procedure is in
[the shared guide](../../shared/skills/README.md#refresh-a-vendored-payload).

From `windows/`, reconcile skills and the plugin with:

```powershell
.\scripts\update-skills.ps1 -NoPull
.\scripts\update-skills.ps1 -Check -NoPull
.\scripts\verify-system.ps1
```

The sync replaces only recorded managed links, removing Claude's old vendored
Ponytail links so the plugin supplies its skills, hook, and commands once.
`agents` receives the six vendored skills. Plugin installation uses user scope;
the marketplace must belong to the manifest's repository. An unrelated
marketplace with the same name is a collision, not something to overwrite.

Restart Claude Code after installation. Plugin options retain their upstream
defaults unless configured by the owner; the webhook URL defaults to empty. The
pinned plugin's hooks use Node.js and support native Windows.
