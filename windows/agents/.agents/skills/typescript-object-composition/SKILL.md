---
name: typescript-object-composition
description: Automatically use this skill whenever working in a TypeScript project. Apply it when reading, editing, reviewing, refactoring, or generating TypeScript code, especially object types, React props, DTOs, API contracts, service interfaces, shared models, and type composition.
---

## Purpose

This is the **default TypeScript type-modeling policy** for any TypeScript project. It governs how object contracts, composed types, and type-level operations are expressed. The goal is readable, maintainable contracts with clear intent - not clever type gymnastics.

---

## Default Usage

- Apply this skill by default whenever working in a TypeScript project.
- Respect explicit, consistently enforced repository conventions - they override this policy.
- Do not rewrite code only for style preference.
- Do not apply aggressively to generated files, non-TypeScript projects, simple local one-off object literals, or public API changes unless explicitly requested.

---

## Core Decision Rules

### Use `interface` for named object contracts

When a type represents a named, stable object shape - a DTO, API contract, React props, service interface, or shared model - declare it as an `interface`.

```ts
// ? Named object contract
interface UserProfile {
  id: string;
  name: string;
  email: string;
}
```

### Use `interface extends` for object composition

When building a composed object from existing object contracts, prefer `interface extends` over repeated intersections (`&`). It is explicit, readable, and avoids hidden property conflicts.

```ts
// ? Object composition via interface extends
interface AuditedEntity {
  createdAt: Date;
  updatedAt: Date;
}

interface Order extends AuditedEntity {
  orderId: string;
  totalAmount: number;
}
```

### Use `type` for type-level operations

Use `type` for unions, mapped types, conditional types, tuples, primitive aliases, utility transformations, and discriminated unions - anywhere `interface` cannot express the model.

```ts
// ? Union
type PaymentMethod = "CREDIT_CARD" | "BANK_TRANSFER" | "PROMPTPAY";

// ? Discriminated union
type TransactionEvent =
  | { kind: "authorized"; authCode: string }
  | { kind: "declined"; reason: string }
  | { kind: "refunded"; refundId: string };

// ? Mapped type
type ReadonlyUserProfile = Readonly<UserProfile>;

// ? Conditional type
type Nullable<T> = T extends null | undefined ? never : T;

// ? Tuple
type Coordinate = [latitude: number, longitude: number];

// ? Primitive alias
type UserId = string;
```

### Avoid intersection conflicts

Intersecting interfaces with incompatible property types collapses those properties to `never`, producing a type that can never be satisfied. This is a silent hazard.

```ts
// ? Problematic intersection - id collapses to never
type A = { id: string };
type B = { id: number };
type AB = A & B; // { id: never }
```

When conflict is possible, use `Omit` to surgically exclude the conflicting property before composing.

```ts
// ? Safe composition with Omit
interface BaseEntity {
  id: string;
  createdAt: Date;
}

interface ExternalRecord {
  id: number; // different id type
  source: string;
}

type MergedRecord = Omit<ExternalRecord, "id"> & BaseEntity;
// id is now string from BaseEntity - no conflict
```

### Avoid accidental declaration merging

`interface` supports declaration merging. This is useful when intentionally augmenting framework or module declarations (e.g., Express `Request`, Next.js session types), but it can cause subtle bugs if two unrelated interfaces share a name in the same scope.

```ts
// ?? Accidental merge - both declarations silently combine
interface Config {
  timeout: number;
}
interface Config {
  retries: number;
} // merged, not an error
```

Use `type` when merging is not the intent.

---

## Refactoring Workflow

When refactoring existing TypeScript code toward this policy:

1. **Inspect existing project conventions first.** If the repo consistently uses `type` for everything or enforces a linter rule, respect that convention.
2. **Identify exported object contracts and composed object types.** Focus on DTOs, service interfaces, API response shapes, and React props.
3. **Convert object intersections to `interface extends` only when safe.** Verify no property name conflicts exist before converting.
4. **Preserve `type` aliases where `interface` cannot express the model** - unions, mapped types, conditional types, tuples.
5. **Run the project's type-check, lint, and tests if available** (`tsc --noEmit`, `eslint`, `jest`) before considering the refactor complete.
6. **Avoid broad churn.** Refactor the file or module in scope - do not cascade changes across unrelated files.

---

## Review Checklist

Before choosing `interface` or `type`, ask:

- [ ] Is this a **named object contract**?  `interface`
- [ ] Is this **object composition** from existing contracts?  `interface extends`
- [ ] Is this a **union, mapped type, conditional type, tuple, or primitive alias**?  `type`
- [ ] Are intersections **hiding conflicting properties** that may collapse to `never`?  use `Omit` or redesign
- [ ] Is this type **exported broadly** and part of a public API?  prefer stability, avoid unnecessary rewrites
- [ ] Does the repo **enforce a different convention** via lint or team agreement?  follow the repo
- [ ] Are **public API changes** covered by tests or type-checking?  verify before changing

---

## Suggested Agent Behavior

- Keep refactors **small and mechanical** - convert one module at a time.
- **Explain decisions briefly** when converting: "Changed intersection to `interface extends` - no property conflicts found."
- **Avoid dogmatic rewrites** - a working `type` intersection that carries no risk is not worth touching.
- **Preserve exported APIs** where possible - renaming or restructuring exported types is a breaking change.
- **Prefer readable contracts over clever type gymnastics** - if a type requires a comment to understand, consider simplifying the model.

---

## Examples

### Named object contract

```ts
interface PaymentRequest {
  amount: number;
  currency: "THB" | "USD";
  reference: string;
}
```

### Object composition via `interface extends`

```ts
interface AuditedEntity {
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

interface Invoice extends AuditedEntity {
  invoiceId: string;
  totalAmount: number;
  status: "DRAFT" | "ISSUED" | "PAID";
}
```

### Union type

```ts
type TransferStatus = "PENDING" | "PROCESSING" | "COMPLETED" | "FAILED";
```

### Problematic intersection conflict

```ts
// ? id collapses to never - this type can never be satisfied
type InternalRecord = { id: string; source: "internal" };
type ExternalRecord = { id: number; source: "external" };
type Record = InternalRecord & ExternalRecord;
// { id: never; source: never }
```

### Safe replacement using `Omit`

```ts
// ? Exclude conflicting property before composing
type SafeRecord = Omit<ExternalRecord, "id" | "source"> & InternalRecord;
```

### Before / after refactor: intersection props  `interface extends`

```ts
// ? Before - intersection used for object composition
type AuditFields = {
  createdAt: Date;
  updatedAt: Date;
};

type CustomerAccount = AuditFields & {
  accountId: string;
  ownerId: string;
  balance: number;
};
```

```ts
// ? After - interface extends for clear, explicit object composition
interface AuditFields {
  createdAt: Date;
  updatedAt: Date;
}

interface CustomerAccount extends AuditFields {
  accountId: string;
  ownerId: string;
  balance: number;
}
```
