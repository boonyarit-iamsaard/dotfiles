# Direct push to `main`; contributions limited to the owner

Changes land on `main` by direct push from each platform, with no pull requests,
no feature branches and no CI. The repository stays public, but only the owner
contributes: pull requests are turned off, issue creation is limited to
collaborators, and Wiki and Projects are off. A ruleset on `main` blocks force
pushes and deletion, with no pull request rule and no bypass. We chose this
because most changes are small and frequent (switching the active theme,
updating LazyVim on WSL), so a pull request per change costs more than it
catches, and the owner is the only collaborator anyway.

## Considered Options

- **Protected `main` with required pull requests and CI (issue #15)**: rejected;
  every theme switch or plugin update would need a branch, a pull request and a
  merge, and the per-platform verification it would enforce already lives in the
  platform rule and its issues.
- **A ruleset that lists the owner in its bypass**: rejected; agents push with
  the owner's credentials, so a bypass for the owner is a bypass for them, and
  the ruleset would then guard against nothing.
- **Making the repository private**: rejected; the owner wants it public.

## Consequences

`pnpm format:check` and `git diff --check` stay manual steps before each commit.
Others can still fork the repository and comment on existing issues; GitHub
offers no permanent setting to stop either. A deliberate force push to `main`
means setting the ruleset to Disabled, pushing, and setting it back to Active.
