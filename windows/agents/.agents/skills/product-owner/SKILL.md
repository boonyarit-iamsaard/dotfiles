---
name: product-owner
description: "Bootstrap a new feature OR a new project from a raw requirement. Use this skill whenever the user describes a new feature, capability, or change they want built - even informally. Triggers on phrases like 'I want to build...', 'we need a feature that...', 'add support for...', 'new feature:', or any raw requirement statement that hasn't been formalized yet. Also triggers for project-level requests like 'new project', 'start a project', 'we're building a system', or 'I need a PRD' - in which case this skill runs in Project Mode and produces a project-requirements-document.md instead. Always use this skill before any other agent skill is invoked on a new feature or project."
---

# Product Owner Skill

Transform a raw requirement into a structured package that downstream agents can
consume without needing conversation history. This skill is the entry point of the entire
agent workflow - nothing downstream has a home until this skill runs.

This skill has two modes. Identify which applies before proceeding.

**Feature Mode** - A single capability, change, or story within an existing or new project.
Triggered when the user describes a feature, story, or specific requirement.

**Project Mode** - A full system or product being defined from scratch.
Triggered when the user says "new project", "start a project", "I need a PRD",
or describes a system at a scope that spans multiple features.

---

## Feature Mode

### F-Step 1 - Scan for Existing Features

Before creating anything, check whether a `docs/features/` directory exists and identify
the highest existing `F-NNNN` prefix to determine the next ID.

```
docs/features/F-0001-*/    next ID is F-0002
docs/features/             (empty)  first ID is F-0001
docs/features/             (not found)  create it, first ID is F-0001
```

Announce the assigned ID to the user before proceeding.

If `docs/project/project-requirements-document.md` exists, read it before proceeding.
The feature must align with the project's epics, constraints, and out-of-scope items.

---

### F-Step 2 - Extract Requirements From the Conversation

Mine the current conversation before asking any questions. Extract:

- The core capability being requested
- The user role(s) who will use it
- The business value or outcome expected
- Any constraints, tech preferences, or non-goals already stated
- Any explicit out-of-scope statements

The goal is to arrive at the clarification step with as much pre-filled as possible.

---

### F-Step 3 - Fill Gaps With Targeted Questions

Ask only what the conversation does not already answer. Common gaps:

- Who is the primary user/role for this feature?
- What does success look like - what can they do after this is built?
- Are there any hard constraints (tech stack, deadline, dependencies on other features)?
- Is anything explicitly out of scope?

Keep this focused. One or two questions maximum. Do not ask for information already stated.

---

### F-Step 4 - Assess Phase Expectations

Based on the requirement complexity, assess which phases are expected vs. optional:

| Signal                                                    | ADR Expectation |
| --------------------------------------------------------- | --------------- |
| New tech, pattern, or integration not yet used in project | `?? Likely`     |
| Multiple viable implementation approaches exist           | `?? Likely`     |
| Straightforward CRUD or UI with established patterns      | `? Optional`    |
| User explicitly asks for an ADR                           | `? Required`    |

| Signal                                                                   | DevOps Expectation |
| ------------------------------------------------------------------------ | ------------------ |
| Feature introduces new infrastructure, service, or deployment target     | `?? Likely`        |
| Feature requires new environment variables, secrets, or pipeline changes | `?? Likely`        |
| Feature is purely application-layer with no infra changes                | `? Optional`       |

Flag both assessments in README.md. The user makes the final call at each handover.

---

### F-Step 5 - Write requirements.md

Write to `docs/features/{F-NNNN}-{slug}/specs/requirements.md`.

Follow the **Feature Requirements Template** section below exactly.

---

### F-Step 6 - Bootstrap README.md

Write to `docs/features/{F-NNNN}-{slug}/README.md`.

Follow the **Feature README Template** section below exactly.

Mark PO phase as `? Accepted`. All other phases `? Pending` or `? Optional` per F-Step 4 assessment.

---

### F-Step 7 - Self-Check Before Presenting

- [ ] Every user story has at least two acceptance criteria
- [ ] Every acceptance criterion is testable (Given/When/Then - no vague language)
- [ ] Non-goals section explicitly states at least one thing that is out of scope
- [ ] README phase table reflects both ADR and DevOps assessments from F-Step 4
- [ ] Feature slug is kebab-case and descriptive of the subject, not the outcome
- [ ] Cross-feature dependencies listed by ID only - no content duplication
- [ ] If `docs/project/project-requirements-document.md` exists, verify this feature aligns with it

---

### F-Step 8 - Save and Present

Output paths:

- `docs/features/{F-NNNN}-{slug}/specs/requirements.md`
- `docs/features/{F-NNNN}-{slug}/README.md`

---

## Project Mode

### P-Step 1 - Check for Existing Project Artifacts

Check whether `docs/project/` exists. If it does and `project-requirements-document.md`
already exists, inform the user and ask if they want to update it or start a new one.

If the directory does not exist, create it.

---

### P-Step 2 - Extract Project Context From the Conversation

Mine the current conversation before asking any questions. Extract:

- The system or product being built and the problem it solves
- The intended users or customer segments
- Business goals, success metrics, or outcomes expected
- Known tech stack, platform, or infrastructure constraints
- Any features, epics, or capabilities already identified
- Any explicit out-of-scope statements or deferred phases

---

### P-Step 3 - Fill Gaps With Targeted Questions

Ask only what the conversation does not already answer. Common gaps for a project PRD:

- Who are the primary users and what problem does this solve for them?
- What does a successful v1 look like - what must be true at launch?
- Are there hard constraints on stack, timeline, team size, or budget?
- Are there known integrations or external dependencies?
- What is explicitly deferred to a later phase?

Keep this to two or three questions maximum.

---

### P-Step 4 - Write project-requirements-document.md

Write to `docs/project/project-requirements-document.md`.

Follow the **Project Requirements Document Template** section below exactly.

---

### P-Step 5 - Self-Check Before Presenting

- [ ] Problem statement is clear - a developer unfamiliar with the project can understand why this is being built
- [ ] At least three epics or capability areas identified
- [ ] Each epic has at least one success criterion
- [ ] Non-functional requirements cover at minimum: security, performance, and scalability expectations
- [ ] Explicitly deferred items are listed - not left implicit
- [ ] Tech stack constraints (if any) are in Constraints, not preferences
- [ ] Document is self-contained - no reliance on conversation history

---

### P-Step 6 - Save and Present

Output path:

- `docs/project/project-requirements-document.md`

---

## Feature Requirements Template

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

## Feature README Template

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
| DevOps    | ? Optional | devops-engineer  | {reason if likely/required} |
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

| Artifact                 | Status     | Path                           |
| ------------------------ | ---------- | ------------------------------ |
| requirements.md          | ? Accepted | specs/requirements.md          |
| technical-spec.md        | ? Pending  | specs/technical-spec.md        |
| infrastructure-design.md | ? Optional | specs/infrastructure-design.md |
| test-plan.md             | ? Pending  | specs/test-plan.md             |
| ADR(s)                   | ? Optional | adr/                           |
| review-{date}.md         | ? Pending  | reviews/                       |

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

## Project Requirements Document Template

```markdown
# Project Requirements Document

**Project:** {Project Name}
**Status:** Accepted
**Author:** product-owner
**Date:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD

---

## 1. Executive Summary

2-3 paragraphs. Describe the system being built, the problem it solves, and
who it is for. Write for a developer who is joining the project cold.
Answer: _"What is this, why does it exist, and who benefits?"_

---

## 2. Problem Statement

Describe the current state and the gap this system addresses.
Be specific about pain points, inefficiencies, or unmet needs.

---

## 3. Goals and Success Criteria

| Goal | Success Criterion  | Priority                                        |
| ---- | ------------------ | ----------------------------------------------- |
| ...  | Measurable outcome | ?? Must Have / ?? Should Have / ?? Nice to Have |

---

## 4. Users and Stakeholders

| Role | Description | Primary Needs |
| ---- | ----------- | ------------- |
| ...  | ...         | ...           |

---

## 5. Epics and Capability Areas

High-level groupings of related functionality. These will be broken into
individual features (F-NNNN) as the project progresses.

### EP-001: {Epic Title}

**Description:** What this capability area covers.
**Key outcomes:** What users can do when this is complete.
**Priority:** ?? Must Have / ?? Should Have / ?? Nice to Have

---

### EP-002: {Epic Title}

**Description:** ...
**Key outcomes:** ...
**Priority:** ...

---

## 6. Non-Functional Requirements

### Security

- ...

### Performance

- ...

### Scalability

- ...

### Availability

- ...

### Compliance / Regulatory

- ...

---

## 7. Constraints

Hard limits only - not preferences. These bound every downstream decision.

- ...

---

## 8. Assumptions

Conditions assumed to be true that, if they change, would require this document
to be revisited.

- ...

---

## 9. Out of Scope (This Version)

Explicitly deferred capabilities or concerns. These are not rejected - they are
intentionally excluded from the current scope.

- ...

---

## 10. Dependencies

External systems, services, teams, or APIs this project depends on.

| Dependency | Type                                   | Nature |
| ---------- | -------------------------------------- | ------ |
| ...        | External API / Internal service / Team | ...    |

If none: _"No external dependencies identified."_

---

## 11. Open Questions

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | ?? High, ?? Medium, or ?? Low | ...    |

If none: _"No open questions at time of writing."_
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
- **In Project Mode, epics are not features.** Do not decompose into user stories
  at the epic level. That happens when a feature is spun up via Feature Mode.
