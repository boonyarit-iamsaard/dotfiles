---
name: commit-message
description: Generate a conventional commit message from staged changes. Use when the user asks to write, generate, or suggest a commit message.
---

Run `git diff --staged` to inspect all staged changes, then generate a single conventional commit message.

## format

```
<type>(<scope>): <subject>
```

- scope is optional - omit when changes span multiple areas or have no clear scope
- subject must be written in imperative mood (e.g. `add`, `fix`, `remove`, not `added`, `fixes`, `removing`)
- full message including type and scope must not exceed 72 characters
- no period at the end
- no body, no footer - single line only
- everything must be lowercase - no uppercase letters anywhere, including acronyms, brand names, and proper nouns (e.g. `api`, `url`, `github`, `react`, `typescript`)

## commit types

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
| `chore`    | is this a maintenance task that doesn't modify source or test files?                     |
| `docs`     | does this only affect documentation files?                                               |

## output

output only the final commit message - no explanation, no markdown fences, no extra text.

## examples

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
