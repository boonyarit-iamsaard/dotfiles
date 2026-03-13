---
name: senior-developer
description: "Implement or verify a feature that has an accepted technical-spec.md. Use this skill when the user says 'implement this', 'write the code', 'dev phase', 'build it' (Mode 1 - agent implements), OR when the user says 'I wrote the code', 'I implemented this', 'post-implementation', 'document my work' (Mode 2 - verify and document human implementation). Reads technical-spec.md, requirements.md, and any ADRs. Mode 1 writes production-level code to src/. Mode 2 verifies the existing code against the spec and produces implementation-notes.md. Always invoke this skill after the tech-lead skill has accepted a feature and before the qa-engineer skill runs."
---

# Senior Developer Skill

This skill has two modes. Identify which applies before proceeding.

**Mode 1 - Agent Implements:** The agent writes production-level code from the spec.
Triggered when the user hands off without mentioning prior implementation.

**Mode 2 - Verify and Document:** The user has already written the code. The agent
verifies the implementation against the spec, flags gaps, and produces
`implementation-notes.md`. Triggered when the user mentions they have already coded it.

In both modes: this skill does not make design decisions - those belong to the tech
lead and ADR phases. Gaps and ambiguities are surfaced, not improvised.

---

## Mode 1 - Agent Implements

### M1 Step 1 - Read the Feature Package

Read in this order:

1. `docs/features/{F-NNNN}-{slug}/README.md` - confirm Tech Lead phase is `? Accepted`
2. `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md` - full implementation blueprint
3. `docs/features/{F-NNNN}-{slug}/specs/requirements.md` - user stories and acceptance criteria
4. `docs/features/{F-NNNN}-{slug}/adr/` - any ADRs; decisions here override spec where they conflict

If Tech Lead phase is not `? Accepted`, stop and inform the user. Do not proceed.

If any ADR exists, read it fully before writing a single line of code. ADR decisions
are non-negotiable constraints for this phase.

---

### M1 Step 2 - Scan the Existing Codebase

Before writing any code, scan the relevant areas of `src/` to identify:

- Naming conventions in use (files, classes, functions, variables)
- Established patterns for the component types being built (services, controllers, hooks, etc.)
- Error handling approach already in use
- Existing utilities or abstractions that should be reused

Follow what exists. Do not introduce a new pattern when an established one already covers the need.

---

### M1 Step 3 - Identify Spec Gaps

Before writing code, flag any of the following found in the spec:

- Ambiguous field types or missing nullability
- Unspecified error handling for a stated error condition
- Implementation Notes that are contradictory or incomplete
- Anything marked as an open question that blocks implementation

List gaps to the user and wait for resolution. Do not proceed with assumptions on
blocking gaps. For non-blocking minor ambiguities, document the assumption made
in a code comment and proceed.

---

### M1 Step 4 - Implement

Follow the Implementation Notes sequence from technical-spec.md exactly.
Create files in the order specified to respect dependencies between them.

**Code standards (non-negotiable):**

- Readability over brevity - if two approaches are equivalent, choose the one
  that is easier to read cold
- No magic numbers or unexplained constants - use named constants with comments
- Explicit error handling - never silently swallow exceptions
- No dead code - do not leave commented-out blocks or unused imports
- One responsibility per function - if a function needs a "and" in its description,
  split it
- Inline comments for non-obvious logic - explain _why_, not _what_
- Follow the spec's component locations exactly - do not reorganize the file structure

**Per stack:**

For Spring Boot (Java/Kotlin):

- Follow layered architecture: Controller  Service  Repository
- Use constructor injection, never field injection
- Return typed response objects, never raw Map or Object
- Use @Slf4j for logging - no System.out.println
- Handle checked exceptions explicitly at the service boundary

For .NET (C#):

- Follow layered architecture: Controller  Service  Repository
- Use constructor injection via DI container
- Return typed result objects or use Result<T> pattern
- Use ILogger<T> for logging
- Handle exceptions at the service boundary with meaningful messages

For React/TypeScript:

- Functional components only
- Co-locate types with the component or in a dedicated types file in the same folder
- No any - type everything explicitly
- Extract reusable logic into custom hooks
- Keep components focused - if JSX exceeds ~100 lines, consider decomposition

For Node.js/TypeScript:

- Type everything - no implicit any
- Async/await over raw Promise chains
- Centralized error handling middleware
- No business logic in route handlers

---

### M1 Step 5 - Self-Check Before Presenting

- [ ] Every user story acceptance criterion from requirements.md is addressed by the implementation
- [ ] Every component listed in technical-spec.md Section 3 has been implemented
- [ ] Every API endpoint in technical-spec.md Section 4 has been implemented with correct request/response shapes
- [ ] All non-goals from requirements.md are absent from the implementation
- [ ] No unresolved TODOs left in code - open questions are in README.md instead
- [ ] No dead code, unused imports, or commented-out blocks
- [ ] Error handling is explicit at every boundary stated in the spec
- [ ] Codebase conventions from M1 Step 2 scan are followed consistently

---

### M1 Step 6 - Update README.md

Append a row to the Decision Log:

```
| YYYY-MM-DD | Dev phase accepted | {N} files written to src/ |
```

Update the Phase Tracker:

- `Dev`  `? Accepted`

---

### M1 Step 7 - Save and Present

List every file written with its path relative to project root.
Update and present README.md alongside the implemented files.

---

## Mode 2 - Verify and Document

### M2 Step 1 - Read the Feature Package

Read in this order:

1. `docs/features/{F-NNNN}-{slug}/README.md` - confirm Tech Lead phase is `? Accepted`
2. `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md` - the contract to verify against
3. `docs/features/{F-NNNN}-{slug}/specs/requirements.md` - acceptance criteria
4. `docs/features/{F-NNNN}-{slug}/adr/` - any ADRs; deviations from these are automatic failures
5. Implemented code in `src/` - all files relevant to this feature

If Tech Lead phase is not `? Accepted`, stop and inform the user. Do not proceed.

---

### M2 Step 2 - Verify Implementation Against Spec

Check the implementation against every section of technical-spec.md:

**Components (Section 3):**

- [ ] Every component defined in the spec exists in `src/`
- [ ] Each component is at the specified location
- [ ] Each component's responsibility matches what the spec describes

**API Contracts (Section 4):**

- [ ] Every endpoint is implemented
- [ ] Request shapes match the spec exactly - field names, types, required/optional
- [ ] Response shapes match the spec exactly
- [ ] All documented error responses are handled

**Data Models (Section 5):**

- [ ] All fields are present with correct types
- [ ] Nullability matches the spec
- [ ] Indexes and constraints are applied

**ADR Compliance:**

- [ ] No code contradicts any ADR decision - any deviation is an automatic failure

**Non-Goals:**

- [ ] Nothing from requirements.md non-goals appears in the implementation

---

### M2 Step 3 - Classify Findings

Every gap found in Step 2 must be classified:

| Severity       | Definition                                                                                                                    |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| ?? Blocking    | Spec deviation, missing component, ADR violation, or missing error handling at a boundary. Must be fixed before QA handover.  |
| ?? Recommended | Minor inconsistency, missing inline comment on non-obvious logic, or naming drift from codebase conventions. Should be fixed. |

---

### M2 Step 4 - Determine Outcome

**If blocking findings exist:**

- Do not produce `implementation-notes.md`
- Report all blocking findings clearly with file and location references
- Update README.md Phase Tracker: `Dev`  `?? Blocked`
- Append to Decision Log: `| YYYY-MM-DD | Dev phase blocked | {N} blocking findings from senior-developer Mode 2 |`
- User fixes the code and re-runs Mode 2

**If no blocking findings:**

- Proceed to Step 5

---

### M2 Step 5 - Write implementation-notes.md

Write to `docs/features/{F-NNNN}-{slug}/specs/implementation-notes.md`.

```markdown
# Implementation Notes: {Short Feature Title}

**Feature ID:** F-NNNN
**Status:** Accepted
**Author:** You (verified by senior-developer)
**Date:** YYYY-MM-DD

---

## 1. Verification Result

? Implementation verified against technical-spec.md - no blocking findings.

---

## 2. Actual File Locations

List every file written, with path relative to project root.
Note any locations that differ from what the spec specified and why.

| File | Path      | Deviation from Spec |
| ---- | --------- | ------------------- |
| ...  | `src/...` | None / {reason}     |

---

## 3. Spec Deviations

Document any deliberate differences between what the spec described and what
was implemented. Each deviation must include a reason.

| Spec Section | What Spec Said | What Was Implemented | Reason |
| ------------ | -------------- | -------------------- | ------ |
| ...          | ...            | ...                  | ...    |

If none: _"No deviations from technical-spec.md."_

---

## 4. Edge Cases Handled

Document any edge cases handled in the implementation that were not explicitly
covered in the spec or test plan. These are inputs for the QA engineer.

- ...

If none: _"No additional edge cases beyond those in the spec."_

---

## 5. Recommended Findings

| #    | File      | Location | Finding |
| ---- | --------- | -------- | ------- |
| R-01 | `src/...` | Line N   | ...     |

If none: _"No recommended findings."_

---

## 6. Notes for QA

Anything the QA engineer should know that is not covered in the spec or test plan.

- ...

If none: _"No additional notes for QA."_
```

---

### M2 Step 6 - Update README.md

Append a row to the Decision Log:

```
| YYYY-MM-DD | Dev phase accepted | Implemented by user, verified by senior-developer Mode 2 |
```

Update the Phase Tracker:

- `Dev`  `? Accepted`

Add `implementation-notes.md` to the Artifact Index:

```
| implementation-notes.md | ? Accepted | specs/implementation-notes.md |
```

---

### M2 Step 7 - Save and Present

Output paths:

- `docs/features/{F-NNNN}-{slug}/specs/implementation-notes.md` (new)
- `docs/features/{F-NNNN}-{slug}/README.md` (updated)

---

## On Spec Gaps (Both Modes)

This skill does not improvise on design decisions. The boundary is:

| Situation                                    | Action                                                                    |
| -------------------------------------------- | ------------------------------------------------------------------------- |
| Field type ambiguous but non-blocking        | Assume most restrictive type, add inline comment, proceed                 |
| Error handling not specified for a condition | Flag to user, wait for resolution                                         |
| Implementation sequence unclear              | Follow dependency order (models  repos  services  controllers/components) |
| Spec contradicts an ADR                      | ADR wins - flag the contradiction, implement per ADR                      |
| Requirement not covered by spec              | Flag to user - do not gold-plate                                          |

---

## Writing Principles

- **The spec is the source of truth.** If it is not in the spec, it is not in the code.
  Surface gaps rather than filling them silently.
- **Consistency beats local optimization.** Follow existing patterns even if a newer
  pattern would be marginally better. Inconsistency is a maintenance cost.
- **Comments explain intent, not mechanics.** A comment that says `// increment counter`
  adds no value. A comment that says `// offset by 1 to account for 0-indexed page param`
  does.
- **Error messages are for humans.** Write error messages that a developer or operator
  can act on - not stack traces, not generic "something went wrong".
- **Mode 2 is not a rubber stamp.** Verifying your own work is still a real verification.
  A blocked result in Mode 2 is the same as a blocked result from the code reviewer -
  fix it before moving on.
