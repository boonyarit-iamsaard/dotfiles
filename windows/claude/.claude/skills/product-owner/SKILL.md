---
name: product-owner
description: "Bootstrap a new feature from a raw requirement. Use this skill whenever the user describes a new feature, capability, or change they want built - even informally. Triggers on phrases like 'I want to build...', 'we need a feature that...', 'add support for...', 'new feature:', or any raw requirement statement that hasn't been formalized yet. This skill creates the feature folder, writes requirements.md with structured user stories and acceptance criteria, and bootstraps README.md as the Scrum Master's tracking document. Always use this skill before any other agent skill is invoked on a new feature."
---

# Product Owner Skill

Transform a raw requirement into a structured feature package that downstream agents can
consume without needing conversation history. This skill is the entry point of the entire
agent workflow - nothing downstream has a home until this skill runs.

---

## Workflow

### Step 1 - Scan for Existing Features

Before creating anything, check whether a `docs/features/` directory exists and identify
the highest existing `F-NNNN` prefix to determine the next ID.

```
docs/features/F-0001-*/    next ID is F-0002
docs/features/             (empty)  first ID is F-0001
docs/features/             (not found)  create it, first ID is F-0001
```

Announce the assigned ID to the user before proceeding.

---

### Step 2 - Extract Requirements From the Conversation

Mine the current conversation before asking any questions. Extract:

- The core capability being requested
- The user role(s) who will use it
- The business value or outcome expected
- Any constraints, tech preferences, or non-goals already stated
- Any explicit out-of-scope statements

The goal is to arrive at the clarification step with as much pre-filled as possible.

---

### Step 3 - Fill Gaps With Targeted Questions

Ask only what the conversation does not already answer. Common gaps:

- Who is the primary user/role for this feature?
- What does success look like - what can they do after this is built?
- Are there any hard constraints (tech stack, deadline, dependencies on other features)?
- Is anything explicitly out of scope?

Keep this focused. One or two questions maximum. Do not ask for information already stated.

---

### Step 4 - Assess Phase Expectations

Based on the requirement complexity, assess which phases are expected vs. optional:

| Signal                                                    | ADR Expectation |
| --------------------------------------------------------- | --------------- |
| New tech, pattern, or integration not yet used in project | `?? Likely`     |
| Multiple viable implementation approaches exist           | `?? Likely`     |
| Straightforward CRUD or UI with established patterns      | `? Optional`    |
| User explicitly asks for an ADR                           | `? Required`    |

Flag this in README.md. The user makes the final call at each handover - this is guidance only.

---

### Step 5 - Write requirements.md

Write to `docs/features/{F-NNNN}-{slug}/specs/requirements.md`.

Follow the **Requirements Template** section below exactly.

---

### Step 6 - Bootstrap README.md

Write to `docs/features/{F-NNNN}-{slug}/README.md`.

Follow the **README Template** section below exactly.

Mark PO phase as `? Accepted`. All other phases `? Pending` or `? Optional` per Step 4 assessment.

---

### Step 7 - Self-Check Before Presenting

Before presenting files, verify:

- [ ] Every user story has at least two acceptance criteria
- [ ] Every acceptance criterion is testable (Given/When/Then - no vague language)
- [ ] Non-goals section explicitly states at least one thing that is out of scope
- [ ] README phase table reflects the ADR assessment from Step 4
- [ ] Feature slug is kebab-case and descriptive of the subject, not the outcome
- [ ] Cross-feature dependencies listed by ID only - no content duplication

---

### Step 8 - Save and Present

Save both files and present to the user using `present_files`.

Output paths:

- `docs/features/{F-NNNN}-{slug}/specs/requirements.md`
- `docs/features/{F-NNNN}-{slug}/README.md`

---

## Requirements Template

```markdown
# Requirements: {Short Feature Title}

**Feature ID:** F-NNNN
**Status:** Accepted
**Author:** product-owner
**Date:** YYYY-MM-DD

---

## 1. Context

2-3 paragraphs. Describe the problem this feature solves and why it matters.
Write for a developer who is unfamiliar with the project history.
Answer: _"What gap exists today, and what changes when this is built?"_

---

## 2. Scope

**In scope:**

- ...

**Out of scope:**

- ...

---

## 3. Constraints

Hard limits only - not preferences. These are the non-negotiables that bounded
the solution space before any design decisions were made.

- ...

---

## 4. Dependencies

Cross-feature dependencies referenced by ID only.

| Feature ID | Title | Nature of Dependency                                     |
| ---------- | ----- | -------------------------------------------------------- |
| F-NNNN     | ...   | Requires its API contract / shares its data model / etc. |

If none: _"No cross-feature dependencies."_

---

## 5. User Stories

### US-001: {Title}

**As a** {role}
**I want** {capability}
**So that** {business value}

#### Acceptance Criteria

- [ ] Given {context}, when {action}, then {outcome}
- [ ] Given {context}, when {action}, then {outcome}

---

### US-002: {Title}

**As a** {role}
**I want** {capability}
**So that** {business value}

#### Acceptance Criteria

- [ ] Given {context}, when {action}, then {outcome}
- [ ] Given {context}, when {action}, then {outcome}

---

## 6. Non-Goals

Explicitly state what this feature will not do. This section exists to prevent
scope creep and to give downstream agents a clear boundary.

- ...

---

## 7. Open Questions

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | ?? High, ?? Medium, or ?? Low | ...    |

If none: _"No open questions at time of writing."_
```

---

## README Template

```markdown
# F-NNNN: {Feature Title}

**Status:** In Progress
**Created:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD

---

## Summary

One paragraph. What this feature does and why it exists.
Written for an agent picking this up cold - no conversation history assumed.

---

## Phase Tracker

| Phase     | Status     | Owner            | Notes                       |
| --------- | ---------- | ---------------- | --------------------------- |
| PO        | ? Accepted | product-owner    |                             |
| Tech Lead | ? Pending  | tech-lead        |                             |
| ADR       | ? Optional | adr-author       | {reason if optional/likely} |
| Dev       | ? Pending  | senior-developer |                             |
| QA        | ? Pending  | qa-engineer      |                             |
| Review    | ? Pending  | code-reviewer    |                             |

**Status legend:**

- ? Accepted - complete and signed off
- ? Pending - not yet started
- ?? In Progress - agent currently working this phase
- ?? Blocked - waiting on dependency or open question
- ? Optional - may be skipped; owner decides at handover
- ? Skipped - explicitly bypassed with reason

---

## Artifact Index

| Artifact          | Status     | Path                    |
| ----------------- | ---------- | ----------------------- |
| requirements.md   | ? Accepted | specs/requirements.md   |
| technical-spec.md | ? Pending  | specs/technical-spec.md |
| test-plan.md      | ? Pending  | specs/test-plan.md      |
| ADR(s)            | ? Optional | adr/                    |
| review-{date}.md  | ? Pending  | reviews/                |

---

## Dependencies

| Feature ID | Title | Nature |
| ---------- | ----- | ------ |
| F-NNNN     | ...   | ...    |

If none: _"No cross-feature dependencies."_

---

## Open Blockers

| #   | Blocker | Raised By | Priority |
| --- | ------- | --------- | -------- |

If none: _"No open blockers."_

---

## Decision Log

Chronological record of phase completions, handovers, and significant decisions.
Never delete entries.

| Date       | Event             | Notes                |
| ---------- | ----------------- | -------------------- |
| YYYY-MM-DD | PO phase accepted | Feature bootstrapped |
```

---

## Writing Principles

- **Write for an agent picking this up cold.** No chat history will be available.
  Every artifact must be self-contained.
- **Acceptance criteria must be testable.** If a QA agent cannot write a test case
  directly from the criterion, rewrite it.
- **Non-goals are not optional.** At least one explicit non-goal is required.
  It focuses every downstream agent and prevents scope creep.
- **The "So that" clause is load-bearing.** It tells the tech lead and developer
  _why_ this exists - which informs tradeoff decisions without re-reading everything.
- **Constraints are hard limits only.** If it's a preference, it belongs in the
  options assessment, not constraints. Preferences passed as constraints mislead
  downstream agents.
