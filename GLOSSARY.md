# Dotfiles

Personal machine configuration, installed by linking packages into `$HOME`.

## Platforms

**Platform**: An environment this repo configures (macOS, Windows, WSL), defined
by where the session runs, not by the hardware. _Avoid_: machine, OS, host

**Behavior change**: A change to anything a platform reads or runs, verified on
every platform it affects. _Avoid_: platform change, real change

**Inert change**: A change that leaves every platform's behavior as it was:
formatting, documentation, and lint fixes in documentation. _Avoid_:
non-behavior change, cosmetic change

**Shared file**: A file kept once under `shared/` because two or more platforms
use it. A file only one platform uses stays in that platform's folder. _Avoid_:
common file, global file

## Theming

**Theme**: A named colour scheme applied across all tools (Dark 2026, Default
Dark Modern, Catppuccin Mocha). _Avoid_: colorscheme (nvim-only), flavour

**Palette**: The single authoritative set of colours for a theme, owned by that
theme's upstream (`dark-2026.nvim`, Catppuccin, VS Code for Default Dark
Modern). _Avoid_: porting reference, colour list

**Theme extra**: One tool's config fragment for a theme, published alongside
that theme's palette and vendored into this repo at a pinned upstream revision.
_Avoid_: port, hand copy

**Hand port**: One tool's theme file written by hand from a theme's palette,
where the upstream ships no theme extra for that tool. _Avoid_: port, copy

**Theme variant**: A tool's file holding everything theme-specific for one
theme, loaded on top of that tool's shared base config. _Avoid_: theme config,
full copy

**Active theme**: The theme a machine currently applies to every themed tool,
chosen on that machine and never committed. _Avoid_: current theme, selected
theme

**Default theme**: The theme a machine applies when no active theme has been
chosen there (Catppuccin Macchiato). _Avoid_: fallback theme, base theme

## Skill sync

**Consumer**: An agent tool whose skill directory receives managed links
(`agents`, `claude`). _Avoid_: target, tree

**Managed link**: A symlink in a consumer's skill directory that the skill sync
owns and may replace or remove. _Avoid_: synced skill, owned link

**Personal skill**: A skill the owner writes, kept once in this repo and given
to every consumer. _Avoid_: local skill, shared skill

**Upstream skill**: A skill from the owner's fork of Matt Pocock's skills,
linked from that fork's checkout. _Avoid_: Matt skill, external skill

**Vendored skill**: A third-party skill whose files are copied into this repo at
a pinned upstream version (`impeccable`, `ponytail`). _Avoid_: installer-owned
skill, unmanaged skill

**Sync session**: One run of the skill sync: pull, unlink the consumers,
reconcile managed links, relink, with relinking guaranteed on failure. _Avoid_:
update, sync run

## Maintenance scripts

**Step**: One named unit of maintenance work with a severity that decides
whether its failure fails the script. _Avoid_: task, job

**Step group**: An ordered set of steps that stops at its first failure (the APT
chain). _Avoid_: pipeline, chain

**Precondition**: A step whose failure aborts its script, or its step group.
_Avoid_: guard, check
