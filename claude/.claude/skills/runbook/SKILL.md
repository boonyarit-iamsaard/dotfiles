---
name: runbook
description: Research the current official docs and write a step-by-step runbook a human reads and executes, then accompany them through it with read-only checks. Use for provisioning cloud services, account/IAM setup, dashboard configuration, or any ops procedure the human must perform. For capturing many values into .env or CI secrets, use wizard instead.
---

# Runbook

A **runbook** is a Markdown document the human reads and executes, one step at
a time, for an operational procedure: standing up a cloud service, wiring
accounts and IAM, configuring a dashboard, a one-off cutover. You write it from
the provider's **current** official docs, then act as the human's
**companion** while they work through it.

The human runs every mutating action. Your commands during a run are
**read-only**: describe, list, get, `--help`. Credentials, MFA and secrets stay
with the human; the runbook names where a value is entered, never the value.

Every step is **cited**: it links the official page that backs it, fetched in
this session. Training-data recall goes stale fast for CLI flags, console
layouts and service limits, so a step with no source fetched today is a gap to
research, not a step to write.

The skeleton and one worked step are in [template.md](template.md).

## Process

### 1. Scope

Input is an issue or spec file, or a free-text goal.

- From a file: read it and everything it links (a parent spec, ADRs). Its
  acceptance criteria become the runbook's step map.
- From free text: restate the goal and a "done when" list, and confirm it
  with the user.

Read the repo for constraints the procedure must honour: region, naming, a
public repository, an existing IaC tool.

**Done when:** you hold an ordered list of outcomes, each traceable to an
acceptance criterion or confirmed "done when" item.

### 2. Research

Research inline, so the docs stay in context for the run:

1. context7 for CLI and SDK references.
2. WebFetch on the provider's own docs domain (`docs.aws.amazon.com`,
   `docs.railway.com`, …) for service guides and console paths.
3. WebSearch only to locate an official page; cite the page, never the search.

Record for each outcome: the page URL, the exact console path or command,
prerequisites, quotas, costs, and anything the docs mark irreversible.

**Done when:** every outcome maps to at least one official page fetched in
this session, and every CLI command matches its current reference page.

### 3. Decisions

The docs often fork: two ways to enable a feature, a setting that depends on
account type, a capability that may be unavailable in a region. Put each fork
to the user with a recommendation, and wait. Record the answers in the
runbook's Decisions section.

**Done when:** no step depends on an option the user has not chosen.

### 4. Write

Copy [template.md](template.md) to a `runbooks/` folder beside the source
issue's `issues/` folder, named after the issue (e.g.
`runbooks/01-aws-foundation.md`). With no issue, follow the repo's existing
notes convention, else use the scratchpad. Fill it:

- **Prerequisites**: tools to install (check with `command -v`), access the
  human needs, region.
- **Steps** in dependency order, each with every field in the template's
  worked step. Mark irreversible steps `⚠️ Irreversible` and name what cannot
  be undone. Console paths carry "per docs, verify on screen": docs trail the
  UI.
- **Placeholders** for every account ID, email, ARN, hostname and secret:
  `<BACKUPS_ACCOUNT_ID>`, `<ROOT_EMAIL>`. The runbook is safe to commit to a
  public repository.

**Done when:** every outcome from step 1 is covered by a step that ticks its
acceptance criterion, and the document holds no real identifier.

### 5. Review gate

Stop. Give the user the runbook's path and ask them to read it. Companion mode
starts only when they say to begin. If they edited the file, re-read it first.

### 6. Companion

Work through the steps as the human reports progress:

- When they report a step done, run its **Verify** check if it is read-only
  and their session can run it; otherwise ask them for what the check shows.
  On a pass, tick the step's checkbox and the matching checkbox in the source
  issue.
- When the screen differs from the doc, re-fetch the cited page, correct the
  step in the runbook, and log the difference in the Run log.
- Append to the Run log: date, steps completed, every deviation from the
  docs. Entries stay as safe to publish as the rest of the runbook.

**Resuming** in a new session: read the runbook and start at the first
unticked step. If the "Docs checked" date is more than 30 days old, re-fetch
the sources of the remaining steps first, update any that changed, and log it.

**Done when:** every step is ticked and every source-issue criterion it covers
is ticked, or the Run log records why one was left open.
