# Ponytail maintenance

[Ponytail](https://github.com/DietrichGebert/ponytail) is vendored as plain
skills so the dotfiles manifests stay the only owners of user-wide agent files.

## Layout and ownership

- `skills\vendor\ponytail` holds the six upstream skills (`ponytail`,
  `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help`,
  `ponytail-review`) and the MIT `LICENSE`.
- `manifests\skills.json` links each skill into both user-wide skill roots.

The payload was copied on 2026-11-14 from upstream commit `96608e0` (plugin
version 5.3.3), taking only the `skills\<name>` folders. The full commit is
recorded as `vendor.ponytail.commit` in `manifests\skills.json`;
`scripts\check-manual-updates.ps1` (run at the end of `update-system`) reports
when upstream `main` has moved.

The upstream plugin's hooks, status line, and task board ("band") are
intentionally omitted. They write a per-turn CSV ledger under
`~\.config\ponytail` and can post to a webhook. `/ponytail-help` still describes
those plugin-only features; they do nothing here.

## Refresh

1. Clone upstream into an empty directory outside this repository.
2. Replace each `skills\vendor\ponytail\<name>` folder with upstream
   `skills\<name>`, and refresh `LICENSE`.
3. Review the complete diff, including any new skill or tool permission. Add a
   new upstream skill to `manifests\skills.json` deliberately.
4. Update `vendor.ponytail.commit` in `manifests\skills.json` and the commit and
   version above, then run:

```powershell
.\scripts\update-skills.ps1 -NoPull
.\scripts\update-skills.ps1 -Check -NoPull
.\scripts\test-update-skills.ps1
pnpm format:check
git diff --check
```
