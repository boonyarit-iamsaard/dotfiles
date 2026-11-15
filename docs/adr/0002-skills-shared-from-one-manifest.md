# Skills shared from one manifest; third-party skills vendored at a pin

Every platform installs the same skills from one manifest,
`shared/skills/skills.json`. Personal skills live once under `shared/skills/`.
Upstream skills come from the owner's fork of Matt Pocock's skills, checked out
per platform. `impeccable` and `ponytail` are vendored under
`shared/skills/vendor/` at the pins the manifest records. Ponytail is also
installed as a Claude plugin from its marketplace, pinned in the same manifest,
because only the plugin carries its session hook and slash commands; the
vendored copy serves the `agents` consumer. Each platform's existing sync reads
the manifest. We chose this so a skill changes in one place and reaches every
platform with the same bytes, the same way ADR-0001 vendors theme extras.

## Considered Options

- **Installer-owned `impeccable` (`npx impeccable` per platform)**: rejected;
  each machine drifts to whatever version it last updated to, and Git cannot
  show what is installed.
- **Vendored Ponytail skills only**: rejected; Claude loses the hook that keeps
  Ponytail on for the whole session.
- **Personal skills in the skills fork**: rejected; the fork tracks Matt's
  upstream, and mixing owners there invites merge conflicts.

## Consequences

Updating `impeccable` or `ponytail` is a deliberate pin bump that changes every
platform, so it is verified on each. The macOS and WSL Python syncs stay
separate scripts for now; merging them is a later cleanup.
