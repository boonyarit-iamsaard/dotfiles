---
name: typescript-house-style
description: TypeScript house style — the defaults for all TypeScript work. Use when writing, refactoring, or reviewing TypeScript (choosing interface vs type, deriving types, modeling value sets or errors, typing external data, shaping modules, functions, or control flow), or when another skill needs TypeScript style defaults.
---

This is a house style: apply it by default to every piece of TypeScript you
write or review. An explicit repo convention (linter rule, consistent existing
usage, CLAUDE.md) outranks any rule here; where the repo is silent, the house
style is the convention. Apply it to the code you're already changing — never
rewrite generated files or untouched modules for style alone.

When the repo's linter can enforce one of these rules (e.g. Biome
`useBlockStatements` for braced `if`s), enable it — a machine-enforced rule
never regresses.

Tiebreaker for anything this style doesn't list: consistency, explicitness,
readability — write code other people like to read.

## Object contracts

| Shape                                                | Use                 |
| ---------------------------------------------------- | ------------------- |
| named object contract                                | `interface`         |
| contract composed from existing contracts            | `interface extends` |
| union or discriminated union                         | `type`              |
| mapped, conditional, indexed-access, or utility type | `type`              |
| tuple or primitive alias                             | `type`              |
| intentional framework/module augmentation            | `interface`         |

Named object contracts include DTOs, API request/response bodies, React props,
service interfaces, and shared models. Avoid declaration merging unless the
augmentation is intentional.

Prefer `interface extends` over `A & B` for composed contracts. When converting
an intersection, check every overlapping property name first: each overlap must
be compatible, removed with `Omit`, or the declaration left as `type` —
incompatible overlaps silently collapse to `never`.

```ts
interface BaseEntity {
  id: string;
}

interface ExternalRecord {
  id: number;
  source: string;
}

type MergedRecord = Omit<ExternalRecord, "id"> & BaseEntity;
```

Keep exported names stable — renaming an exported contract is a breaking
change.

## Derived types

Derive shallow, publish flat. Mapped and conditional types earn their cost
when they keep one source of truth and stay one hop deep — one mapped type, no
nested conditionals, no recursion. Anything consumers import presents as a
flat named shape: an `interface`, or a mapped result immediately named and
never re-derived. This matters most when authoring a library — exported types
are read through hovers and `.d.ts` files, where a flat shape is legible and a
derivation chain is soup.

## Fixed value sets

Never `enum`. A string-literal union is the default; when the values must be
enumerated at runtime, derive the union from an `as const` object:

```ts
type Verdict = "correct" | "incorrect" | "error";

const Difficulty = { easy: 1, normal: 2, hard: 3 } as const;
type Difficulty = (typeof Difficulty)[keyof typeof Difficulty];
```

## Annotations

The best type is the inferred type — annotate only where the annotation _is_
the contract. Exported functions whose return type is an authored contract
(domain operations, services, package entry points) declare it, so an
accidental change surfaces at the source instead of at call sites. Where the
inferred type is the product — React components, hooks returning tuples,
schema builders — rely on inference. Locals, private helpers, and initialized
variables always infer.

## Escape hatches

`any`, type-assertion `as`, and non-null `!` are banned — production code and
tests alike. Each has a typed replacement:

- Untyped data is `unknown`; it acquires a type through narrowing or schema
  parsing (see Boundaries).
- Shape-checking without widening is `satisfies`, not `as`.
- A value that "can't be null here" gets an explicit narrowing check or an
  invariant assertion function, not `!`.

`as const` is literal-widening control, not an assertion — use it freely.

One carve-out: a branded type needs one `as` inside its constructor. That
assertion lives in a single named constructor or parser with an honest
signature (`function toUserId(raw: string): UserId`) — or costs nothing via a
schema library's `.brand()` — and `as` still never appears at a use site.

## Modules

- Filenames are kebab-case.
- Named exports; a default export only where a framework requires one
  (Next.js pages, config files).
- Named imports mirror named exports. For project code this is a hard rule —
  never `import * as helpers from "./utils"`. For dependencies, follow the
  library's idiom: a default import when it ships one, a namespace import
  where that is how the library is used (`import * as v from "valibot"`).
- Node builtins are imported with the `node:` protocol and named imports:
  `import { readFile } from "node:fs/promises"` — the prefix marks them as
  builtins, not npm packages.
- Barrel files (`index.ts` re-export hubs) exist only as a package's public
  entry point, never inside app code.

## Errors

Expected domain failures are values: return a discriminated union
(`{ ok: true; value } | { ok: false; error }`, or the repo's Result type) so
failure is part of the checked signature. `throw` is reserved for bugs and
unrecoverable faults — invariant violations, misconfiguration, infrastructure
loss.

The Result type is hand-rolled first: one minimal `Result<T, E>` per repo,
plus at most a few helpers. A Result library (neverthrow etc.) only when the
repo already uses one — its chaining idiom infects every signature, and plain
Results with braced early-return guards read better to more people.

**Error flow across layers.** Third-party code throws for expected failures;
that idiom stops at the adapter. Each adapter (repository, HTTP client, fs
wrapper) catches, converts domain-meaningful outcomes into typed Results, and
lets genuine infrastructure faults keep throwing. A raw third-party error
never escapes its adapter. The edge (HTTP handler, UI root) holds the single
`try/catch` for thrown faults — nothing below it catches throws.

Error vocabulary scales with the architecture: a small app may share one
error union; once explicit layers exist (application / domain / persistence),
each layer owns its vocabulary and an error crosses a boundary only through
an explicit mapping — an exhaustive `switch` the compiler checks.

## Boundaries

Parse, don't assert. Data crossing a trust boundary — network responses,
storage reads, env vars, user input — enters as `unknown` and acquires its
type through schema validation. Use the repo's schema library; greenfield
defaults to zod.

## Functions

- `function` declarations for named functions; arrows only inline. The
  keyword is the signal: `function` declares behavior, `const` declares a
  value — scanning the keyword tells them apart without reading further.
  Named functions, including React components and one-line helpers, use
  `function`; it also hoists, names stack frames, and takes overloads and
  generics cleanly. Arrow functions appear only where their form earns it:
  inline callbacks (`items.map((x) => x.id)`) and code that must capture the
  enclosing `this`.
- Up to two positional parameters; at three or more — or as soon as any
  parameter is a boolean — switch to a single options object.
- `readonly` on array and object parameters the function doesn't mutate.
- A component's props interface is named `[ComponentName]Props`
  (`ButtonProps` for `Button`) — never a bare `Props`, which collides on
  import and says nothing in search results or hovers. If the conventional
  name conflicts, pick a descriptive alternative rather than falling back to
  `Props`.
- Every React component declares its props parameter as `Readonly<Props>` —
  the zero-exception case of the readonly rule, since props are never
  mutated. It is a shallow tripwire against direct mutation, not deep
  immutability, and linters flag it only inconsistently (SonarQube S6759
  misses wrapped, generic, and imported-props components) — apply it to
  every component regardless.

  ```tsx
  interface ButtonProps {
    label: string;
    onPress: () => void;
  }

  function Button({ label, onPress }: Readonly<ButtonProps>) {
    return <button onClick={onPress}>{label}</button>;
  }
  ```

- A generic type parameter must link two positions (parameter↔return,
  parameter↔parameter); a type parameter that appears once is an `unknown` in
  disguise.

## Control flow

Every `if` takes a braced block — no braceless bodies, no one-liners like
`if (!user) return null;`. Guard clauses stay, braced:

```ts
if (!user) {
  return null;
}
```

An unbraced `if` is where a later edit adds a second statement that isn't
actually inside it; the uniform block shape keeps control flow scannable.

## Verification

After applying the style, run the repo's typecheck (and lint, if present). If
you cannot run them, report that.
