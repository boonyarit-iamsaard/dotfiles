---
name: commit-message
description:
  Commit message from staged changes, matched to the repository's own commit
  conventions. Use before every commit - when the user asks for a message, and
  whenever you are about to commit your own work.
---

Generate one conventional commit message from the staged diff, written so it
looks like it belongs in this repository's history.

## Steps

1. Run `git diff --staged` and inspect the complete staged diff. This step is
   complete only when every staged file's behavioral role is accounted for.
2. Run `git log --no-merges --pretty=format:'%s' -50` and derive the
   repository's pattern (see
   [Matching the repository](#matching-the-repository)).
3. Pick the type and scope per [Commit Types](#commit-types) and the scope
   habit, preferring what the repository already uses for this kind of change.
4. Output exactly one line satisfying every format rule - no explanation, no
   markdown fences, no extra text.

## Matching the repository

The sampled subjects show how this project words things. This skill wrote them,
so treat them as authoritative for wording and mirror them:

- **verbs** - reuse the imperative verbs already in use rather than a synonym
  (`configure`, not `set up`; `initialize`, not `bootstrap`). Reach for a new
  verb only when no existing one fits the change.
- **naming** - name tools and features the way history names them
  (`postgres and mailpit`, `github actions`), including how much is spelled out.
- **granularity** - match the observed subject length and level of detail. Terse
  histories get terse subjects; descriptive histories get descriptive ones.
- **scope** - mirror the scope habit: if subjects carry a `(scope)`, use one and
  reuse an existing scope name verbatim; if they don't, omit it.

Skip any subject that isn't conventional-commit shaped (a scaffold's
`Initial commit`). With no history yet, set the pattern using the defaults
below.

## Format

```
<type>(<scope>): <subject>
```

- scope is optional; omit it when changes span multiple areas or have no clear
  scope, and otherwise follow the scope habit
- subject must be written in imperative mood (e.g. `add`, `fix`, `remove`, not
  `added`, `fixes`, `removing`)
- subject line including type and scope must not exceed 72 characters
- no period at the end
- the subject line is the whole output; trailers a harness appends after it
  (`Co-Authored-By`, `Signed-off-by`) belong to that harness, so leave them
  alone
- everything must be lowercase - no uppercase letters anywhere, including
  acronyms, brand names, and proper nouns (e.g. `api`, `url`, `github`, `react`,
  `typescript`)

A `commitlint` config in the repository encodes these same rules for the
commit-msg hook. Where one exists it is authoritative: read it and follow it.

## Commit Types

apply these rules top-to-bottom and stop at the first match:

| type       | rule                                                                                     |
| ---------- | ---------------------------------------------------------------------------------------- |
| `feat`     | does this introduce new capability the end-user can directly interact with?              |
| `fix`      | does this correct an error or crash negatively impacting user experience?                |
| `style`    | does this only affect visual presentation or code formatting without altering logic?     |
| `refactor` | does this restructure code for readability without changing behavior or adding features? |
| `perf`     | does this make the application faster or reduce resource consumption?                    |
| `test`     | does this involve only adding, modifying, or correcting automated tests?                 |
| `build`    | does this relate to project building, packaging, or dependencies?                        |
| `ci`       | does this relate only to continuous integration configuration or scripts?                |
| `docs`     | does this only affect documentation files?                                               |
| `chore`    | is this a maintenance task that doesn't modify source, test, or documentation files?     |

## Examples

Baseline shapes, to be bent toward whatever the sampled history shows:

```
feat(auth): add jwt-based login endpoint
fix(booking): prevent double reservation on concurrent requests
refactor(user): extract validation logic into separate function
build: add eslint and prettier configuration
ci: update github actions node version to 22
chore: update .gitignore to exclude .env files
docs: add setup instructions to readme
test(room): add unit tests for availability check
perf(query): add index on reservations created_at column
style: format files with prettier
```

Worked example - history reads:

```
chore: configure postgres and mailpit for local development
ci: configure github actions workflow and act
chore: configure prettier and editorconfig
```

Pattern: no scopes, `configure` as the setup verb, tool names spelled out. A
staged Tailwind setup therefore yields `chore: configure tailwind css`, not
`chore(build): set up Tailwind`.
