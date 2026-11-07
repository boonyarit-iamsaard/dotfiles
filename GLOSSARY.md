# Dotfiles

Personal machine configuration, installed by linking packages into `$HOME`.

## Theming

**Theme**:
A named colour scheme applied across all tools (catppuccin mocha, dark 2026).
_Avoid_: colorscheme (nvim-only), flavour

**Palette**:
The single authoritative set of colours for a theme, owned by that theme's upstream repo.
_Avoid_: porting reference, colour list

**Theme extra**:
One tool's config fragment for a theme, published alongside that theme's palette and vendored into this repo at a pinned upstream revision.
_Avoid_: port, hand copy

**Theme variant**:
A tool's file holding everything theme-specific for one theme, loaded on top of that tool's shared base config.
_Avoid_: theme config, full copy

## Skill sync

**Consumer**:
An agent tool whose skill directory receives managed links (`agents`, `claude`).
_Avoid_: target, tree

**Managed link**:
A symlink in a consumer's skill directory that the skill sync owns and may replace or remove.
_Avoid_: synced skill, owned link

**Installer-owned skill**:
A skill installed by its own installer into a consumer, which the skill sync and stow must leave untouched (`impeccable`).
_Avoid_: excluded skill, unmanaged skill

**Sync session**:
One run of the skill sync: pull, unlink the consumers, reconcile managed links, relink, with relinking guaranteed on failure.
_Avoid_: update, sync run

## Maintenance scripts

**Step**:
One named unit of maintenance work with a severity that decides whether its failure fails the script.
_Avoid_: task, job

**Step group**:
An ordered set of steps that stops at its first failure (the APT chain).
_Avoid_: pipeline, chain

**Precondition**:
A step whose failure aborts its script, or its step group.
_Avoid_: guard, check
