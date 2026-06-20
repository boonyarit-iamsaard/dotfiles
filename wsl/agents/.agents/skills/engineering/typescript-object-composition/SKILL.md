---
name: typescript-object-composition
description: TypeScript object composition. Use when choosing or reviewing `interface` vs `type` for named object contracts, composed object shapes, DTOs, React props, API contracts, service interfaces, or exported models.
---

Use a contract-first policy for TypeScript object shapes: stable object
contracts should read like contracts, and type-level operations should stay as
`type` aliases.

## Steps

1. Inspect the local convention before changing anything. This step is complete
   when you know whether the repo consistently prefers `interface`, `type`, or a
   linter-enforced rule for object contracts.
2. Classify each type in scope with the decision table below. This step is
   complete when every changed declaration has one classification.
3. If converting an intersection, check every overlapping property name first.
   This step is complete only when each overlap is either compatible, removed
   with `Omit`, or left unchanged.
4. Keep the refactor narrow. This step is complete when exported API names and
   behavior are preserved, or any intentional public API change is explicit.
5. Run the project's relevant type-check, lint, or tests. If you cannot run
   them, report that.

## Decision Table

| Shape                                                   | Prefer               |
| ------------------------------------------------------- | -------------------- |
| named object contract                                   | `interface`          |
| object contract composed from existing object contracts | `interface extends`  |
| union or discriminated union                            | `type`               |
| mapped, conditional, indexed-access, or utility type    | `type`               |
| tuple or primitive alias                                | `type`               |
| simple local one-off object shape                       | leave existing style |
| intentional framework/module augmentation               | `interface`          |

Named object contracts include DTOs, API request/response bodies, React props,
service interfaces, and shared models.

## Composition Rules

- Prefer `interface extends` over `A & B` for composed object contracts when no
  property conflicts exist.
- Do not convert intersections blindly. Incompatible overlaps collapse to
  `never`.
- Use `Omit` before composition when one side should replace a conflicting
  property.
- Keep `type` when the composition is a real type operation, not just an object
  contract.

```ts
interface AuditFields {
  createdAt: Date;
  updatedAt: Date;
}

interface CustomerAccount extends AuditFields {
  accountId: string;
  ownerId: string;
}
```

```ts
interface BaseEntity {
  id: string;
  createdAt: Date;
}

interface ExternalRecord {
  id: number;
  source: string;
}

type MergedRecord = Omit<ExternalRecord, "id"> & BaseEntity;
```

## Caveats

- Repository conventions override this policy.
- Do not rewrite generated files or unrelated modules for style preference.
- Avoid declaration merging unless augmentation is intentional.
- Preserve exported names where possible; renaming exported contracts can be a
  breaking change.
