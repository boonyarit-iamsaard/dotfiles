# Shared skills

Every platform installs the same skills from one manifest,
[`skills.json`](skills.json) (see
[ADR 0002](../../docs/adr/0002-skills-shared-from-one-manifest.md)). Each
platform's skill sync reads it and links every listed skill into each consumer:

| Consumer | Skill directory    | Read by                              |
| -------- | ------------------ | ------------------------------------ |
| `agents` | `~/.agents/skills` | Codex and other Agent Skills clients |
| `claude` | `~/.claude/skills` | Claude Code                          |

Until [issue #16](https://github.com/boonyarit-iamsaard/dotfiles/issues/16) is
done, only WSL reads this manifest; macOS and Windows still install from their
own copies.

## What lives here

- **Personal skills** (`commit-message`, `edit-prose`, `runbook`,
  `typescript-house-style`): written by the owner and kept once, in this folder.
  `edit-prose` links its rules from the `humanizer` checkout at
  `~/workspace/personal/humanizer`.
- **Vendored skills** in `vendor/`: third-party payloads kept byte for byte at
  the pins recorded under `vendor` in the manifest. `.gitattributes` and
  `.prettierignore` exempt them from whitespace and formatting changes.
  - `vendor/impeccable/codex` and `vendor/impeccable/claude` are the
    per-consumer builds of the Impeccable skill;
    `vendor/impeccable/claude-agents` holds its Claude Code subagents, which
    each platform links into `~/.claude/agents`.
  - `vendor/ponytail/<name>` holds Ponytail's six skills for the `agents`
    consumer.

Upstream skills from the owner's fork of Matt Pocock's skills are not copied
here. The manifest records the fork's URL and categories, and each platform
links them from its own checkout.

## The manifest

- `repository`: the skills fork and the categories each platform links.
- `vendor`: the pinned version or commit of each vendored payload.
- `plugins.claude`: Claude Code plugins, each pinned to a marketplace ref.
  Ponytail is installed this way as well, because only the plugin carries its
  session hook and slash commands.
- `consumers`: each consumer's skill directory, relative to the home directory.
- `skills`: each skill's name and its source under this folder. A string source
  goes to every consumer. A map from consumer to source covers per-consumer
  builds. A map that leaves a consumer out needs a `reason`, as the Ponytail
  skills have: Claude gets them from the plugin.

## Refresh a vendored payload

A pin bump changes every platform, so verify it on each.

**Impeccable.** In an empty directory outside this repository, run:

```sh
npx --yes impeccable@<version> install -y --providers=claude,codex --scope=project --no-hooks
```

Replace `vendor/impeccable/codex` with `.agents/skills/impeccable`,
`vendor/impeccable/claude` with `.claude/skills/impeccable`, and the files in
`vendor/impeccable/claude-agents` with `.claude/agents/impeccable-*.md`. Leave
out `scripts/bin` and `scripts/.impeccable`, which hold a platform binary and
runtime state. Keep `vendor/impeccable/LICENSE` (Apache 2.0), then set
`vendor.impeccable.version`. Never run `npx impeccable update` in a home
directory: it writes over the managed links.

From the repository root, preserve executable permission on both Unix launchers
and install the pinned engine for this machine:

```sh
chmod +x shared/skills/vendor/impeccable/codex/scripts/impeccable \
  shared/skills/vendor/impeccable/claude/scripts/impeccable
shared/skills/vendor/impeccable/codex/scripts/impeccable engine-probe
shared/skills/vendor/impeccable/claude/scripts/impeccable engine-probe
```

The first probe needs network access and write access to `~/.impeccable`; the
launcher verifies the download against its vendored checksums. Both probes
should report `impeccable-engine` with the version in `scripts/VERSION`. Git
must track both launchers as mode `100755`. A launcher without executable
permission makes Codex's Impeccable hook fail with exit code 126.

**Ponytail.** Clone upstream into an empty directory. Replace each
`vendor/ponytail/<name>` with upstream `skills/<name>` and refresh `LICENSE`
(MIT). Set `vendor.ponytail.commit` and the `ref` of the Ponytail entry under
`plugins.claude` to the same commit, so the plugin and the vendored skills stay
in step. Add a new upstream skill to `skills` deliberately.

Review the complete diff, including new tools and permissions, before
committing.
