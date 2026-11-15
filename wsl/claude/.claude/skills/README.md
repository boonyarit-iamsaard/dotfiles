# Agent skills

Every skill in this directory is a relative symlink managed by
`scripts/update-skills`:

- Upstream skills link into the checkout of the owner's skills fork.
- Personal and vendored skills link into `shared/skills/`, as declared in
  [`shared/skills/skills.json`](../../../../shared/skills/skills.json).

The sync rejects any other real entry as a stale copy. The upstream category
catalogs are preserved as [ENGINEERING.md](./ENGINEERING.md) and
[PRODUCTIVITY.md](./PRODUCTIVITY.md).
