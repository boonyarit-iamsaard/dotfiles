---
name: qa-engineer
description: "Produce a test plan for a feature that has accepted requirements.md and technical-spec.md. Use this skill when the user says 'write the test plan', 'QA phase', 'what should we test', or hands off a feature for test coverage design. Reads requirements.md for acceptance criteria and technical-spec.md for component boundaries, API contracts, and data models, then produces test-plan.md covering unit, integration, and negative path scenarios. Always invoke this skill after the senior-developer skill has completed a feature."
---

# QA Engineer Skill

Produce a test plan that gives the developer agent — or a human — unambiguous,
executable test cases. Every acceptance criterion in requirements.md must map to at
least one test case. Every API endpoint and data boundary in technical-spec.md must
have at least one negative/edge case covered.

This skill designs the test plan. It does not write test framework code unless
explicitly asked — that is an implementation task for the developer agent.

---

## Workflow

### Step 1 — Read the Feature Package

Read in this order:

1. `docs/features/{F-NNNN}-{slug}/README.md` — confirm Dev phase is `✅ Accepted`
2. `docs/features/{F-NNNN}-{slug}/specs/requirements.md` — acceptance criteria are the primary input
3. `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md` — component boundaries, API contracts, data models
4. `docs/features/{F-NNNN}-{slug}/adr/` — any ADRs; decisions here may introduce additional test requirements
5. `docs/features/{F-NNNN}-{slug}/specs/implementation-notes.md` — if present, read for actual file locations, spec deviations, extra edge cases, and QA notes left by the developer

If Dev phase is not `✅ Accepted`, stop and inform the user. Do not proceed.

---

### Step 2 — Map Acceptance Criteria to Test Cases

For every acceptance criterion in requirements.md (Given/When/Then format), derive
at least one happy-path test case. Flag any criterion that is untestable — vague
language, missing context, or unmeasurable outcome — and raise it as an open question
before proceeding.

Every test case must trace back to at least one of:

- A user story acceptance criterion (US-XXX / AC-N)
- An API contract in the spec
- A data model constraint in the spec
- A non-functional requirement (auth, performance, security boundary)

---

### Step 3 — Identify Edge Cases and Negative Paths

For each API endpoint in technical-spec.md, derive negative test cases from:

- Every documented error response (400, 404, 500, etc.)
- Boundary values on numeric and string fields
- Null / missing required fields
- Auth boundary — authenticated vs. unauthenticated access

For each data model, derive constraint tests from:

- Non-nullable fields receiving null
- Unique constraint violations
- Foreign key / relationship integrity

---

### Step 4 — Write test-plan.md

Write to `docs/features/{F-NNNN}-{slug}/specs/test-plan.md`.

Follow the **Test Plan Template** section below exactly.

---

### Step 5 — Update README.md

Append a row to the Decision Log:

```
| YYYY-MM-DD | QA phase accepted | test-plan.md written, {N} test cases defined |
```

Update the Phase Tracker:

- `QA` → `✅ Accepted`
- Update `test-plan.md` row in Artifact Index to `✅ Accepted`

---

### Step 6 — Self-Check Before Presenting

- [ ] Every acceptance criterion in requirements.md maps to at least one test case
- [ ] Every API endpoint has at least one negative test case
- [ ] Every data model has at least one constraint test case
- [ ] No test case has a vague expected outcome — all outcomes are specific and verifiable
- [ ] All test cases have a traceability reference (US-XXX, AC-N, or spec section)
- [ ] Untestable criteria are flagged in Open Questions, not silently skipped

---

### Step 7 — Save and Present

Output paths:

- `docs/features/{F-NNNN}-{slug}/specs/test-plan.md` (new)
- `docs/features/{F-NNNN}-{slug}/README.md` (updated)

---

## Test Plan Template

```markdown
# Test Plan: {Short Feature Title}

**Feature ID:** F-NNNN
**Status:** Accepted
**Author:** qa-engineer
**Date:** YYYY-MM-DD
**References:** requirements.md, technical-spec.md

---

## 1. Scope

**In scope:**

- ...

**Out of scope:**

- ...

---

## 2. Test Strategy

Brief description of the testing approach for this feature.
State which test types apply and why.

| Test Type   | Applicable | Rationale |
| ----------- | ---------- | --------- |
| Unit        | Yes / No   | ...       |
| Integration | Yes / No   | ...       |
| E2E         | Yes / No   | ...       |
| Contract    | Yes / No   | ...       |
| Security    | Yes / No   | ...       |

---

## 3. Test Cases

### {TC-001}: {Title}

**Type:** Unit / Integration / E2E / Contract
**Traces To:** US-XXX AC-N / Spec Section N
**Priority:** 🔴 High, 🟡 Medium, or 🟢 Low

**Preconditions:**

- ...

**Steps:**

1. ...
2. ...

**Expected Outcome:**

- ...

---

### {TC-002}: {Title}

**Type:** ...
**Traces To:** ...
**Priority:** ...

**Preconditions:**

- ...

**Steps:**

1. ...
2. ...

**Expected Outcome:**

- ...

---

## 4. Edge Cases and Negative Paths

Document all negative and boundary test cases. Group by component or endpoint.

### {Endpoint or Component}

| TC     | Scenario                    | Input                            | Expected Outcome | Traces To |
| ------ | --------------------------- | -------------------------------- | ---------------- | --------- |
| TC-NNN | Missing required field      | `{ field: null }`                | 400 Bad Request  | Spec §4   |
| TC-NNN | Unauthenticated request     | No auth header                   | 401 Unauthorized | Spec §4   |
| TC-NNN | Boundary value — max length | 256-char string on 255-max field | 400 Bad Request  | Spec §5   |

---

## 5. Data Setup Requirements

Describe any test data, seed records, or environment state required
for test cases to run. Be explicit — do not assume fixtures exist.

| Requirement                    | Used By        | Notes |
| ------------------------------ | -------------- | ----- |
| Authenticated user with role X | TC-001, TC-005 | ...   |
| Existing record with ID Y      | TC-003         | ...   |

If none: _"No special data setup required."_

---

## 6. Open Questions

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | 🔴 High, 🟡 Medium, or 🟢 Low | ...    |

If none: _"No open questions at time of writing."_
```

---

## Writing Principles

- **Test cases are for humans and agents, not just machines.** Write steps and
  expected outcomes that a developer can follow manually if the test suite is not
  yet set up.
- **Traceability is mandatory.** A test case with no reference to a requirement
  or spec section has no justification. If it cannot be traced, it should not exist.
- **Expected outcomes must be specific.** "Should work correctly" is not an outcome.
  "Returns HTTP 200 with `{ id, createdAt }` in response body" is an outcome.
- **Negative paths are not optional.** Happy-path-only test plans are incomplete.
  Every error response documented in the spec must have a corresponding test case.
- **Flag untestable criteria.** Do not silently skip vague acceptance criteria —
  raise them as open questions so the PO or tech lead can sharpen them.
