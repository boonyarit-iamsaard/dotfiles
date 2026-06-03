---
name: scrum-master
description: "Track feature or project phase status, validate phase completion, and assess readiness for the next handover. Use this skill when the user says 'what's the status', 'is this ready for the next phase', 'scrum master check', 'can we hand off to X', 'summarize the feature', 'summarize the project', or any time they want a health check on a feature or project in progress. Reads the full artifact package and reports current phase state, open blockers, and whether the next handover is safe to make. This skill does not produce code or spec artifacts - it owns README.md (features) exclusively and acts as the gatekeeper between phases."
---

# Scrum Master Skill

Track health, validate phase readiness, and maintain README.md as the single
source of truth for workflow state. This skill does not produce implementation
artifacts - it reads what other agents have produced and gives an honest
assessment of where work stands.

When you are about to hand off to the next agent, run this skill first.
It will tell you whether the current phase is actually complete.

This skill covers two scopes:

**Feature scope** - Tracks a single feature (F-NNNN) through its phase lifecycle.
**Project scope** - Reports the state of project-level artifacts
(project-requirements-document.md, system-architecture.md, infrastructure-design.md).

---

## Workflow

There are three modes. Identify which one applies from the user's message.

---

### Mode 1 - Phase Readiness Check

**Triggered by:** "is this ready for X", "can we hand off to X", "check before handover"

#### Step 1 - Identify Scope

Determine whether the check is for a feature (F-NNNN referenced) or a project-level
phase. Read the appropriate artifacts based on scope.

**For feature scope:**

1. `docs/features/{F-NNNN}-{slug}/README.md` - phase tracker, artifact index, blockers
2. The artifact(s) produced by the current phase (per the Artifact Index)
3. Any ADRs if the current phase involved one

**For project scope:**

1. `docs/project/project-requirements-document.md`
2. `docs/project/system-architecture.md` (if phase being checked is Tech Lead or later)
3. `docs/project/infrastructure-design.md` (if phase being checked is DevOps or later)

#### Step 2 - Run the Phase Gate Checklist

Each phase has a specific readiness checklist. Run the one that matches the
phase being completed.

---

**PROJECT-LEVEL GATES**

**PO Project Mode  Tech Lead Project Mode:**

- [ ] `docs/project/project-requirements-document.md` exists and status is `Accepted`
- [ ] At least three epics defined with success criteria
- [ ] Non-functional requirements section covers security, performance, and scalability
- [ ] Out of scope section has at least one explicit entry
- [ ] No open questions marked ?? High that block the tech lead

**Tech Lead Project Mode  DevOps Project Mode:**

- [ ] `docs/project/system-architecture.md` exists and status is `Accepted`
- [ ] Every epic in project-requirements-document.md is addressed by at least one service or component
- [ ] Technology stack decisions are documented with rationale
- [ ] All cross-cutting concerns defined (auth, logging, error handling, API conventions)
- [ ] ADR trigger assessment completed - ADRs written if required
- [ ] No open questions marked ?? High that block DevOps or feature work

**DevOps Project Mode  Feature Development (first feature):**

- [ ] `docs/project/infrastructure-design.md` exists and status is `Accepted`
- [ ] Every service in system-architecture.md has a deployment target defined
- [ ] All environments (dev, staging, prod) are defined
- [ ] CI/CD pipeline stages are defined
- [ ] Secrets management approach is documented
- [ ] No open questions marked ?? High that block implementation

---

**FEATURE-LEVEL GATES**

**PO  Tech Lead:**

- [ ] `requirements.md` exists and status is `Accepted`
- [ ] At least one user story with at least two acceptance criteria
- [ ] Non-goals section has at least one explicit entry
- [ ] No open questions marked ?? High that block the tech lead
- [ ] README.md Phase Tracker shows PO as `? Accepted`
- [ ] If project-requirements-document.md exists, feature aligns with it

**Tech Lead  DevOps (if DevOps phase is not Optional/Skipped):**

- [ ] `technical-spec.md` exists and status is `Accepted`
- [ ] Every user story in requirements.md is addressed by a component or endpoint
- [ ] All API contracts have complete request/response shapes - no TBD fields
- [ ] All data model fields have type and nullability defined
- [ ] ADR trigger assessment completed - ADRs written if required
- [ ] No open questions marked ?? High that block implementation
- [ ] README.md Phase Tracker shows Tech Lead as `? Accepted`
- [ ] If system-architecture.md exists, spec does not contradict it

**Tech Lead  Dev (if DevOps phase is Optional or Skipped):**

- All checks from Tech Lead  DevOps gate above apply.

**DevOps  Dev:**

- [ ] `specs/infrastructure-design.md` exists and status is `Accepted`
- [ ] All infra changes identified in technical-spec.md are covered
- [ ] All secrets and env vars are documented with injection method
- [ ] Deployment steps and rollback procedure are defined
- [ ] README.md Phase Tracker shows DevOps as `? Accepted`

**Dev  QA:**

- [ ] All components in technical-spec.md Section 3 are present in `src/`
- [ ] All API endpoints in technical-spec.md Section 4 are implemented
- [ ] No unresolved TODOs in implemented code
- [ ] No non-goals from requirements.md appear in the implementation
- [ ] If user implemented: `implementation-notes.md` exists and verification result is `?`
- [ ] README.md Phase Tracker shows Dev as `? Accepted`

**QA  Review:**

- [ ] `test-plan.md` exists and status is `Accepted`
- [ ] Every acceptance criterion in requirements.md maps to at least one test case
- [ ] Every API endpoint has at least one negative test case
- [ ] No open questions marked ?? High that block review
- [ ] README.md Phase Tracker shows QA as `? Accepted`

**Review  Done:**

- [ ] `reviews/review-YYYY-MM-DD.md` exists
- [ ] Review verdict is `? Accepted` - zero blocking findings
- [ ] README.md Phase Tracker shows Review as `? Accepted`
- [ ] All phases in tracker are either `? Accepted`, `? Optional`, or `? Skipped`

---

#### Step 3 - Report

State clearly: **Ready** or **Not Ready**.

If Not Ready, list exactly what is missing. Do not hedge - be specific about
what must be resolved before the handover is safe.

If Ready, confirm which agent to hand off to next and what they need to read first.

---

### Mode 2 - Status Summary

**Triggered by:** "what's the status", "summarize the feature", "summarize the project", "where are we"

#### Step 1 - Identify Scope and Read Artifacts

**Feature scope:** Read README.md and all artifacts listed in the Artifact Index
that have status `? Accepted`.

**Project scope:** Read all artifacts in `docs/project/` that exist.

#### Step 2 - Produce Status Report

Report inline - no file written for a status check.

**Feature status format:**

```
Feature: F-NNNN - {title}
Overall Status: {In Progress / Blocked / Complete}

Phase Tracker:
  ? PO           - requirements.md accepted
  ? Tech Lead    - technical-spec.md accepted
  ? DevOps       - Skipped: no infra changes
  ?? Dev          - BLOCKED: see reviews/review-YYYY-MM-DD.md (2 blocking findings)
  ? QA           - pending
  ? Review       - pending

Open Blockers: {N}
  - B-01: [description] - raised by code-reviewer

Next Action: Resolve blocking findings in Dev phase, then re-run code-reviewer.
```

**Project status format:**

```
Project: {Project Name}
Overall Status: {In Progress / Blocked / Ready for Feature Development}

Project Artifact Tracker:
  ? project-requirements-document.md - accepted
  ? system-architecture.md           - accepted
  ? infrastructure-design.md         - pending

Features in Progress: {N}
  - F-0001: {title} - {phase} phase

Next Action: Run devops-engineer to produce infrastructure-design.md.
```

Always end with a **Next Action** - one clear statement of what needs to happen next.

---

### Mode 3 - README Reconciliation

**Triggered by:** "update the readme", "reconcile the feature", "sync the tracker",
or after any phase completion where README.md was not updated by the agent.

#### Step 1 - Read All Artifacts

Read every artifact in the feature folder and compare their stated status
against what README.md currently reflects.

#### Step 2 - Identify Drift

Flag any mismatch between artifact status and README.md Phase Tracker or
Artifact Index. Common drift patterns:

- Agent completed a phase but did not update README.md
- ADR was written but ADR phase still shows `? Optional`
- DevOps phase was skipped but README still shows `? Pending`
- Review found blocking issues but Dev phase still shows `? Accepted`
- Open question was resolved in a spec but still listed in README.md blockers
- infrastructure-design.md was written but not added to Artifact Index

#### Step 3 - Update README.md

Apply all corrections. Append a reconciliation entry to the Decision Log:

```
| YYYY-MM-DD | README reconciled by scrum-master | {brief description of drift corrected} |
```

Present the updated README.md to the user.

---

## README.md Ownership Rules

The Scrum Master owns README.md. Other agents update it as a courtesy after
their phase - but the Scrum Master is the authority. When in doubt about what
README.md should say, run Mode 3 to reconcile against actual artifact state.

**Status values and their meaning:**

| Status         | Meaning                                              |
| -------------- | ---------------------------------------------------- |
| ? Accepted     | Phase complete, artifact signed off, safe to proceed |
| ? Pending      | Not yet started                                      |
| ?? In Progress | Agent currently working this phase                   |
| ?? Blocked     | Waiting on a blocker - do not hand off downstream    |
| ? Optional     | May be skipped; owner decides at handover            |
| ? Skipped      | Explicitly bypassed - reason must be in Decision Log |

**Never delete Decision Log entries.** The log is an audit trail.
Corrections are made by appending, not by editing previous rows.

---

## Full Phase Flow Reference

```
PROJECT LEVEL
�������������
product-owner (Project Mode)    project-requirements-document.md
tech-lead (Project Mode)        system-architecture.md
devops-engineer (Project Mode)   infrastructure-design.md
adr-author                      docs/adr/NNNN-*.md  (any phase, as needed)

FEATURE LEVEL (repeats per feature)
������������������������������������
product-owner (Feature Mode)    requirements.md + README.md
tech-lead (Feature Mode)        technical-spec.md
devops-engineer (Feature Mode)   specs/infrastructure-design.md  [? Optional]
adr-author                      adr/NNNN-*.md  [? Optional]
senior-developer                src/ + implementation-notes.md
qa-engineer                     test-plan.md
code-reviewer                   reviews/review-YYYY-MM-DD.md
scrum-master                    README.md  (gates every handoff)
```

Project-level artifacts are upstream context for all feature work.
Feature specs must not contradict system-architecture.md or infrastructure-design.md.

---

## Writing Principles

- **The Scrum Master reports reality, not optimism.** If a phase gate fails one
  check, the handover is not ready - even if everything else looks good.
- **Next Action is always singular.** Do not give the user a list of options.
  Give one clear next step. If multiple blockers exist, identify the highest
  priority one to resolve first.
- **Status checks do not produce files.** Mode 1 and Mode 2 report inline.
  Only Mode 3 (reconciliation) writes to README.md.
- **Drift is normal, not a failure.** Agents don't always update README.md
  perfectly. The Scrum Master exists precisely to catch and correct this.
- **The DevOps phase gate is real.** A feature that introduces infra changes
  without an accepted infrastructure-design.md is not ready for Dev - regardless
  of how complete the technical-spec.md looks.
