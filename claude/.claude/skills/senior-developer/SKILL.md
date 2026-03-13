---
name: senior-developer
description: "Implement a feature that has an accepted technical-spec.md. Use this skill when the user says 'implement this', 'write the code', 'dev phase', 'build it', or hands off a feature for implementation. Reads technical-spec.md, requirements.md, and any ADRs, then writes production-level code to src/ following the project's established conventions. Prioritizes readability, maintainability, and explicit error handling over clever solutions. Always invoke this skill after the tech-lead skill has accepted a feature and before the qa-engineer skill runs."
---

# Senior Developer Skill

Implement the feature exactly as specified in technical-spec.md. This skill does not make
design decisions - those belong to the tech lead and ADR phases. If a gap or ambiguity
is found in the spec, surface it rather than improvise.

The standard is production-level code: readable, maintainable, explicitly error-handled,
and consistent with patterns already established in the codebase. Clever solutions that
sacrifice clarity are not acceptable.

---

## Workflow

### Step 1 - Read the Feature Package

Read in this order:

1. `docs/features/{F-NNNN}-{slug}/README.md` - confirm Tech Lead phase is `? Accepted`
2. `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md` - full implementation blueprint
3. `docs/features/{F-NNNN}-{slug}/specs/requirements.md` - user stories and acceptance criteria
4. `docs/features/{F-NNNN}-{slug}/adr/` - any ADRs; decisions here override spec where they conflict

If Tech Lead phase is not `? Accepted`, stop and inform the user. Do not proceed.

If any ADR exists, read it fully before writing a single line of code. ADR decisions
are non-negotiable constraints for this phase.

---

### Step 2 - Scan the Existing Codebase

Before writing any code, scan the relevant areas of `src/` to identify:

- Naming conventions in use (files, classes, functions, variables)
- Established patterns for the component types being built (services, controllers, hooks, etc.)
- Error handling approach already in use
- Existing utilities or abstractions that should be reused

Follow what exists. Do not introduce a new pattern when an established one already covers the need.

---

### Step 3 - Identify Spec Gaps

Before writing code, flag any of the following found in the spec:

- Ambiguous field types or missing nullability
- Unspecified error handling for a stated error condition
- Implementation Notes that are contradictory or incomplete
- Anything marked as an open question that blocks implementation

List gaps to the user and wait for resolution. Do not proceed with assumptions on
blocking gaps. For non-blocking minor ambiguities, document the assumption made
in a code comment and proceed.

---

### Step 4 - Implement

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

### Step 5 - Update README.md

Append a row to the Decision Log:

```
| YYYY-MM-DD | Dev phase accepted | {N} files written to src/ |
```

Update the Phase Tracker:

- `Dev`  `? Accepted`

---

### Step 6 - Self-Check Before Presenting

- [ ] Every user story acceptance criterion from requirements.md is addressed by the implementation
- [ ] Every component listed in technical-spec.md Section 3 has been implemented
- [ ] Every API endpoint in technical-spec.md Section 4 has been implemented with correct request/response shapes
- [ ] All non-goals from requirements.md are absent from the implementation
- [ ] No unresolved TODOs left in code - open questions are in README.md instead
- [ ] No dead code, unused imports, or commented-out blocks
- [ ] Error handling is explicit at every boundary stated in the spec
- [ ] Codebase conventions from Step 2 scan are followed consistently

---

### Step 7 - Save and Present

List every file written with its path relative to project root.
Update and present README.md alongside the implemented files.

---

---

## On Spec Gaps

This skill does not improvise on design decisions. The boundary is:

| Situation                                    | Action                                                                    |
| -------------------------------------------- | ------------------------------------------------------------------------- |
| Field type ambiguous but non-blocking        | Assume most restrictive type, add inline comment, proceed                 |
| Error handling not specified for a condition | Flag to user, wait for resolution                                         |
| Implementation sequence unclear              | Follow dependency order (models  repos  services  controllers/components) |
| Spec contradicts an ADR                      | ADR wins - flag the contradiction, implement per ADR                      |
| Requirement not covered by spec              | Flag to user - do not gold-plate                                          |

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
