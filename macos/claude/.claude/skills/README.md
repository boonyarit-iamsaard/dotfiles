# Agent skills

Every skill in this directory is a relative symlink:

- Upstream skills link into the checkout of the owner's skills fork at
  `~/workspace/personal/skills`; `~/dotfiles/macos/scripts/update-skills`
  creates and retires them in the live directory.
- Personal and vendored skills link into `shared/skills/`, as declared in
  [`shared/skills/skills.json`](../../../../shared/skills/skills.json).

The sync rejects any other real entry as a stale copy. Read the live
`ENGINEERING.md` and `PRODUCTIVITY.md` catalogs beside this file for the current
upstream list.
