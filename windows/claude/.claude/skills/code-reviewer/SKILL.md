---
name: code-reviewer
description: "Review implemented code for a feature that has accepted technical-spec.md, requirements.md, and a completed dev phase. Use this skill when the user says 'review the code', 'code review phase', 'review this feature', or hands off a feature for review. Reads the full feature package and implemented code in src/, then produces a structured review report covering spec compliance, code quality, and security concerns. Always invoke this skill after the qa-engineer skill has completed and before the feature is considered done."
---

# Code Reviewer Skill

Produce a structured, actionable review of the implemented feature. The review has
three jobs: verify the implementation matches the spec, enforce code quality standards,
and catch issues a developer agent may have missed.

This is not a rubber stamp. A review that finds nothing is either a sign of excellent
work or insufficient scrutiny - be explicit about which it is.

---

## Workflow

### Step 1 - Read the Feature Package

Read in this order:

1. `docs/features/{F-NNNN}-{slug}/README.md` - confirm QA phase is `? Accepted`
2. `docs/features/{F-NNNN}-{slug}/specs/requirements.md` - acceptance criteria
3. `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md` - the contract the code must satisfy
4. `docs/features/{F-NNNN}-{slug}/specs/test-plan.md` - test coverage expectations
5. `docs/features/{F-NNNN}-{slug}/adr/` - architectural decisions that are non-negotiable
6. `docs/features/{F-NNNN}-{slug}/specs/implementation-notes.md` - if present, read for spec deviations and edge cases documented by the developer
7. Implemented code in `src/` - all files listed in the Dev phase Decision Log entry

If QA phase is not `? Accepted`, stop and inform the user. Do not proceed.

ADR decisions are non-negotiable. Any deviation from an ADR is an automatic
blocking finding regardless of code quality.

---

### Step 2 - Review Against Three Lenses

Evaluate the code against all three lenses before writing the report.
Do not stop at the first finding.

**Lens 1 - Spec Compliance**

- Does the implementation match every component defined in technical-spec.md?
- Do API request/response shapes match the spec exactly?
- Are all data model fields, types, and nullability correct?
- Are non-goals from requirements.md absent from the implementation?
- Does any code contradict an ADR decision?

**Lens 2 - Code Quality**

- Are naming conventions consistent with the existing codebase?
- Is each function/method focused on a single responsibility?
- Is error handling explicit at every boundary stated in the spec?
- Are there any silent exception swallows, magic numbers, or unexplained constants?
- Is there dead code, unused imports, or commented-out blocks?
- Are inline comments explaining _why_ rather than _what_?
- Are there any obvious performance concerns - N+1 queries, unbounded loops, missing pagination?

**Lens 3 - Security and Safety**

- Is user input validated before use?
- Are there any SQL injection, XSS, or injection surfaces?
- Is sensitive data (tokens, passwords, PII) handled correctly - not logged, not exposed in responses?
- Are authorization checks present where the spec requires them?
- Are there any hardcoded credentials or secrets?

---

### Step 3 - Classify Each Finding

Every finding must be classified before writing the report:

| Severity       | Definition                                                                                                                                         |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| ?? Blocking    | Must be fixed before feature can be accepted. Includes ADR violations, spec deviations, security issues, and missing error handling at boundaries. |
| ?? Recommended | Should be fixed but does not block acceptance. Code quality improvements, naming inconsistencies, missing comments on non-obvious logic.           |
| ?? Suggestion  | Optional improvement. Refactoring ideas, alternative approaches worth considering in future iterations.                                            |

---

### Step 4 - Write review-{date}.md

Write to `docs/features/{F-NNNN}-{slug}/reviews/review-YYYY-MM-DD.md`.

Follow the **Review Template** section below exactly.

---

### Step 5 - Update README.md

Append a row to the Decision Log:

```
| YYYY-MM-DD | Review phase completed | {N} blocking, {N} recommended, {N} suggestions |
```

Update the Phase Tracker:

- `Review`  `? Accepted` if zero blocking findings
- `Review`  `?? Blocked` if any blocking findings exist - Dev phase must be reopened

If blocking findings exist, also update Dev phase:

- `Dev`  `?? Blocked` with note: `See reviews/review-YYYY-MM-DD.md`

---

### Step 6 - Self-Check Before Presenting

- [ ] Every ADR decision has been explicitly verified - no ADR left unchecked
- [ ] All three lenses were applied - spec compliance, code quality, security
- [ ] Every finding has a severity classification
- [ ] Every blocking finding includes the exact file and line reference
- [ ] Verdict is clearly stated - Accepted or Blocked
- [ ] If zero findings: explicitly stated that all three lenses were applied and nothing was found

---

### Step 7 - Save and Present

Output paths:

- `docs/features/{F-NNNN}-{slug}/reviews/review-YYYY-MM-DD.md` (new)
- `docs/features/{F-NNNN}-{slug}/README.md` (updated)

---

## Review Template

```markdown
# Code Review: {Short Feature Title}

**Feature ID:** F-NNNN
**Review Date:** YYYY-MM-DD
**Author:** code-reviewer
**Verdict:** ? Accepted / ?? Blocked

---

## Summary

2-3 sentences. Overall assessment of the implementation quality.
If blocked, state the primary reason clearly.

---

## Findings

### ?? Blocking

| #    | File      | Location            | Finding     | Required Action  |
| ---- | --------- | ------------------- | ----------- | ---------------- |
| B-01 | `src/...` | Line N / Function X | Description | What must change |

If none: _"No blocking findings."_

---

### ?? Recommended

| #    | File      | Location            | Finding     | Suggested Action |
| ---- | --------- | ------------------- | ----------- | ---------------- |
| R-01 | `src/...` | Line N / Function X | Description | What to improve  |

If none: _"No recommended findings."_

---

### ?? Suggestions

| #    | File      | Location            | Finding     | Notes                  |
| ---- | --------- | ------------------- | ----------- | ---------------------- |
| S-01 | `src/...` | Line N / Function X | Description | Optional consideration |

If none: _"No suggestions."_

---

## Spec Compliance

| Item                       | Status | Notes |
| -------------------------- | ------ | ----- |
| All components implemented | ? / ?  | ...   |
| API contracts match spec   | ? / ?  | ...   |
| Data models match spec     | ? / ?  | ...   |
| Non-goals absent           | ? / ?  | ...   |
| ADR decisions followed     | ? / ?  | ...   |

---

## Test Coverage Assessment

Based on test-plan.md - not running tests, but verifying that the implementation
structure makes the planned test cases executable.

| Test Case | Testable | Notes |
| --------- | -------- | ----- |
| TC-001    | ? / ?    | ...   |

---

## Required Actions Before Re-review

Only present if Verdict is ?? Blocked.

1. Fix B-01: ...
2. Fix B-02: ...

Once addressed, hand back to code-reviewer for a follow-up review.
```

---

## Writing Principles

- **Be specific, not general.** "Error handling is missing" is not a finding.
  "Service layer in `UserService.java:42` catches `Exception` and returns null
  without logging" is a finding.
- **Reference the spec, not your preference.** Every blocking finding must point
  to a specific requirement, spec section, or ADR that the code violates. Personal
  style preferences belong in suggestions, not blocking findings.
- **A clean review requires explanation.** If all three lenses were applied and
  nothing was found, say so explicitly. An empty findings section without that
  statement is not credible.
- **Blocking means blocking.** Do not downgrade a security issue or ADR violation
  to recommended because the code is otherwise well-written. Severity reflects
  impact, not effort to fix.
