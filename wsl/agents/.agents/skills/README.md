# Agent skills

Skills in this directory have three owners:

- Matt Pocock skills are relative symlinks managed by
  `scripts/update-skills`.
- Personal skills are tracked directly in this dotfiles repository and
  declared per consumer in `CONSUMERS` (`scripts/update_skills.py`); the
  sync rejects any other real entry as a stale upstream copy.
- Installer-owned skills, such as `impeccable`, are ignored by Git.

The upstream category catalogs are preserved as
[ENGINEERING.md](./ENGINEERING.md) and
[PRODUCTIVITY.md](./PRODUCTIVITY.md).
