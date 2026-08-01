# Dotfiles

## Shared agent skills

Matt Pocock's engineering and productivity skills are read from the clean,
read-only checkout at `~/workspace/personal/skills`. Run the synchronizer on
demand to fast-forward that checkout from its existing tracked remote and
reconcile both Agent Skills consumers:

```bash
~/dotfiles/scripts/update-skills
```

The command never commits or pushes. It refuses to pull a checkout with local
changes and uses `git pull --ff-only`.

Preview or diagnose reconciliation with:

```bash
~/dotfiles/scripts/update-skills --dry-run
~/dotfiles/scripts/update-skills --check
```

### One-time migration

The first conversion from copied skills must be previewed before it is run:

```bash
~/dotfiles/scripts/update-skills --dry-run --migrate
~/dotfiles/scripts/update-skills --migrate
```

Migration accepts only files whose Git blobs can be traced to the skills
checkout's history. It snapshots both dotfiles skill packages under
`~/.local/state/dotfiles-skills/backups`, archives verified Matt copies, and
keeps the local `commit-message` and `typescript-object-composition` skills.
The obsolete Matt skills `diagnose`, `to-issues`, `to-prd`, and `zoom-out` are
archived during migration. A failed migration restores moved package copies
and attempts to restore the previous Stow layout.

After migration, dotfiles and GNU Stow own local skills while the synchronizer
owns direct links from `~/.agents/skills` and `~/.claude/skills` to the
read-only checkout. This keeps the dotfiles repository clean when Matt adds or
removes a skill.
