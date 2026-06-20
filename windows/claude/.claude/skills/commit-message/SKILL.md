---
name: commit-message
description: Commit message from staged changes. Use when the user asks for a conventional commit message.
---

Generate one conventional commit message from the staged diff.

## Steps

1. Run `git diff --staged` and inspect the complete staged diff. This step is
   complete only when every staged file's behavioral role is accounted for.
2. Pick the commit type by applying the type rules top-to-bottom and stopping at
   the first matching rule.
3. Choose a scope only when one concise lowercase noun clearly covers the staged
   changes.
4. Output exactly one line that satisfies every format rule.

## Format

```
<type>(<scope>): <subject>
```

- scope is optional; omit it when changes span multiple areas or have no clear
  scope
- subject must be written in imperative mood (e.g. `add`, `fix`, `remove`, not `added`, `fixes`, `removing`)
- full message including type and scope must not exceed 72 characters
- no period at the end
- no body, no footer - single line only
- everything must be lowercase - no uppercase letters anywhere, including acronyms, brand names, and proper nouns (e.g. `api`, `url`, `github`, `react`, `typescript`)

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

## Output

output only the final commit message - no explanation, no markdown fences, no extra text.

## Examples

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
