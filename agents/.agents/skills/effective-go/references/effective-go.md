# Effective Go Reference

Source: <https://go.dev/doc/effective_go>

The source page states that Effective Go was written for Go's 2009 release and is not
actively updated. Use this reference for core idioms, then verify modern features such
as modules, generics, `context`, fuzzing, workspaces, and newer standard-library APIs
against current Go documentation and the local project.

## Formatting

- Use `gofmt` or `go fmt`; do not work around its output.
- Use tabs for indentation as emitted by `gofmt`.
- Go has no fixed line length. Wrap long lines when it improves readability.
- Control structures use braces without parentheses; keep the opening brace on the same
  line as `if`, `for`, `switch`, or `select`.
- Semicolons are inserted by the lexer; source code rarely contains them except in
  classic `for` clauses or compact multi-statement lines.

## Comments And Documentation

- Line comments are the norm.
- Doc comments immediately before top-level declarations are package documentation.
- Package comments should explain package purpose and usage, not restate implementation.
- Exported declarations should have useful comments, especially in libraries.

## Names

- Package names are short, lower-case, single words. Avoid underscores and mixedCaps.
- Package names are part of client code. Choose exported names that read well with the
  package qualifier, such as `bytes.Buffer`, `bufio.Reader`, or `ring.New`.
- Do not use `import .` except for special test cases that must run outside the package.
- Getters do not need `Get`; prefer `Owner()` over `GetOwner()`. Setters commonly use
  `SetOwner(...)`.
- One-method interfaces usually take an agent-noun name: `Reader`, `Writer`,
  `Formatter`, `CloseNotifier`, `Stringer`.
- Give methods conventional names and signatures when matching established concepts:
  `Read`, `Write`, `Close`, `Flush`, `String`, and similar.
- Use `MixedCaps` or `mixedCaps` for multiword names.

## Control Flow

- Prefer guard clauses for errors and other early exits. Keep the normal flow unindented.
- Omit `else` after a branch that ends with `return`, `break`, `continue`, or `goto`.
- Use `if` and `switch` initialization statements to scope temporary values tightly.
- Reuse `err` with `:=` in the same scope when at least one new variable is introduced.
- `for` covers classic loops, while-style loops, infinite loops, ranges, and channel
  receives.
- Use `range` for arrays, slices, strings, maps, and channels. Remember string ranges
  decode UTF-8 into runes.
- Use `_` intentionally when discarding an index or value.
- Use `switch` without an expression as a clearer `if`/`else if` chain when appropriate.
- Go switch cases do not fall through by default. Use comma-separated cases or explicit
  `fallthrough` only when truly intended.
- Use labeled `break` or `continue` sparingly for nested loops.

## Functions

- Multiple return values are idiomatic, especially for `(value, error)`.
- Named result parameters are useful when they clarify meaning or support simple deferred
  cleanup, but avoid them when they obscure control flow.
- Use variadic functions for natural APIs that accept a list of values.
- `defer` places cleanup near acquisition. Be careful with deferred calls in loops and
  with capturing variables.

## Data

- Use `new(T)` for a zeroed `*T` when that is the clearest expression.
- Use composite literals for structured values.
- Use `make` for slices, maps, and channels because it initializes their runtime header.
- Prefer clear slice operations and `append` over manual capacity bookkeeping unless
  profiling or API shape justifies it.
- Maps require initialization before assignment.
- Byte slices are often the natural representation for I/O and text processing.

## Initialization

- Let zero values do useful work. Design types so the zero value is valid when practical.
- Use package-level `var` initialization and `init` only when initialization cannot be
  expressed clearly as declarations.
- Keep `init` simple; avoid hidden ordering dependencies.

## Methods And Interfaces

- Methods can be defined on any named type in the same package, not just structs.
- Choose value receivers for small immutable values; choose pointer receivers for
  mutation, avoiding copies, or consistent method sets.
- Interfaces are satisfied implicitly. Define small interfaces around behavior needed by
  consumers.
- Avoid large "kitchen sink" interfaces.
- Type assertions and type switches are useful at dynamic boundaries, but prefer static
  types when possible.

## Blank Identifier

- Use `_` to ignore unwanted assignment, range, or import values.
- Blank imports should be explicit side-effect imports, usually with a clarifying comment.
- Compile-time interface checks can use blank identifier assignments when they document
  important API contracts.

## Embedding

- Use embedding for composition when promoted methods or fields make the API clearer.
- Do not embed just to save typing if it exposes the wrong surface area.
- Embedded interfaces can compose small interfaces into larger ones.

## Concurrency

- Goroutines are cheap but not free. Make their lifetime, cancellation, and ownership
  explicit.
- Channels communicate and synchronize; choose buffering deliberately.
- Prefer clear ownership over shared mutable state. When shared state is needed, use the
  appropriate synchronization primitives.
- Use `select` to coordinate multiple channel operations.
- Ensure goroutines can exit on errors, cancellation, or closed inputs.

## Errors, Panic, And Recover

- Return errors for ordinary failure paths and handle them explicitly.
- Error messages should add useful context while preserving caller control.
- Reserve `panic` for programmer errors, impossible internal states, or package-level
  conventions where recovery is controlled.
- Use `recover` only inside deferred functions and keep recovery boundaries narrow.

## Review Prompts For Go Work

When reviewing or changing Go code, ask:

- Does `gofmt` produce the final formatting?
- Do names read naturally from the caller's package context?
- Is the successful path easy to scan?
- Are errors handled, wrapped, or returned at the right boundary?
- Are interfaces minimal and located where they are consumed?
- Are zero values, constructors, and initialization behavior clear?
- Are goroutine lifetimes and channel ownership obvious?
- Are tests written in the style already used by the package?
