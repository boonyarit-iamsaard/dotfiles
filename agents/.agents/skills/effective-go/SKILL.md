---
name: effective-go
description: "Apply idiomatic Go guidance derived from Effective Go whenever working in a Go project or with Go source files. Use this skill for Go implementation, refactoring, code review, package/API design, naming, formatting, error handling, interfaces, concurrency, tests, and comments. Trigger whenever a repository contains go.mod, .go files, Go packages, or the user asks about Go."
---

# Effective Go

Use this skill every time the task involves Go code.

This skill is based on the official Effective Go document:
<https://go.dev/doc/effective_go>

Effective Go remains a strong guide to core Go style and idioms, but the Go page notes
that it was written for the 2009 release and is not actively updated. For modules,
generics, newer standard-library APIs, and release-specific behavior, also consult the
current Go docs or the local codebase conventions.

## Workflow

1. Confirm this is a Go project by checking for `go.mod`, `.go` files, package
   directories, or Go tool configuration.
2. Run or preserve standard Go tooling where appropriate: `gofmt`, `go test`,
   `go vet`, and project-specific linters.
3. Before editing, scan nearby Go code for package layout, naming style, error
   handling, context propagation, logging, test style, and concurrency patterns.
4. Apply the Effective Go checklist below while writing, reviewing, or explaining Go.
5. For deeper details, read `references/effective-go.md`.

## Core Checklist

- Let `gofmt` decide formatting. Do not hand-align code or create local formatting style.
- Use short, lower-case, single-word package names when possible. Avoid underscores and
  mixedCaps in package names.
- Name exported identifiers for how callers see them through the package qualifier:
  prefer `bufio.Reader`, `ring.New`, and `once.Do`-style names over repeated package words.
- Use `MixedCaps` or `mixedCaps`, not underscores, for multiword names.
- Do not prefix ordinary getters with `Get`; prefer `Owner()` and `SetOwner(...)`.
- Name one-method interfaces by the method plus `-er` or a conventional equivalent:
  `Reader`, `Writer`, `Formatter`, `Stringer`.
- Keep doc comments directly before exported top-level declarations. Make the comment
  start with the declared name when practical.
- Keep the successful path flowing down the page. Use guard clauses for errors and omit
  unnecessary `else` after `return`, `break`, `continue`, or `goto`.
- Use the short declaration form pragmatically, especially to reuse `err` in the same scope.
- Prefer `for` and `range` idioms over C-style translation. Use the blank identifier
  intentionally when discarding range values.
- Use `switch` where it is clearer than chained conditionals. Remember Go cases do not
  fall through unless `fallthrough` is explicit.
- Return multiple values for useful results plus errors. Handle errors explicitly.
- Keep interfaces small and consumer-shaped. Accept interfaces at boundaries when useful;
  return concrete types unless an interface return is a deliberate API choice.
- Prefer simple composite literals, `make` for slices/maps/channels, and `new` only when
  a zeroed pointer value is the clearest fit.
- Use methods to attach behavior to named types; choose pointer receivers when mutation,
  large copies, or method-set consistency require them.
- Treat goroutines and channels as design tools, not decoration. Make ownership, lifetime,
  cancellation, and error paths clear.
- Use `defer` for cleanup close to acquisition. Account for loop behavior and error
  handling when deferring in repeated operations.
- Avoid `panic` for ordinary error handling. Use `panic`/`recover` only for exceptional
  internal failures or when matching established package behavior.
