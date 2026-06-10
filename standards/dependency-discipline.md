# Dependency discipline

New dependencies are a permanent liability: supply-chain surface, version drift, transitive footprint, and a thing the next reader has to learn. This rule applies to every stack. It triggers primarily when the diff *changes the manifest* — `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pyproject.toml`, or equivalent — plus the hand-rolled-utility case below (in-house reimplementation of a stdlib helper), which involves no manifest change.

## What to flag

- **Adding a package for something the platform already provides** — `request` / `node-fetch` when `fetch` is available, `query-string` for what `URLSearchParams` does, `body-parser` when the framework already parses bodies, `lodash` for a single `_.isEmpty()`, `moment` for a single date format. Propose using the built-in instead. *Severity: Important.*
- **In-house re-implementation of a stdlib helper** — A custom `debounce` / `deepEqual` / `chunk` / `range` added by hand when the standard library or a tiny well-known utility would do. *Severity: Minor.* (The reverse of the previous rule — pragmatism cuts both ways.)
- **Package re-pinned to a less-trusted source** — A diff that changes the version specifier from the upstream registry to a fork, mirror, GitHub branch, or unfamiliar publisher. Almost always a red flag. *Severity: Critical.*
- **Major version bump without a changelog reference in the PR** — `^1.x` → `^2.x` (or equivalent) without the PR description mentioning the breaking changes that were checked. *Severity: Important.*
- **Same dependency listed twice** — A package that appears in both `dependencies` and `devDependencies` (npm), or duplicated under different version constraints in the same lockfile. *Severity: Important.*
- **Abandoned or unmaintained package** — Adding a dep whose last release was years ago, or whose repo is archived. *Severity: Important.*

## What NOT to flag (pragmatism guard)

- Industry-standard, broadly-adopted, actively-maintained packages. Examples (non-exhaustive): `pg`, `zod`, `pino`, `fastify`, `bullmq`, `kysely`, `drizzle-orm`, `react`, `react-router`, `tanstack/query`, `vitest`, `playwright`, `pytest`, `requests`, `httpx`, `pydantic`, `serde`, `tokio`, `clap`. The same principle applies in other ecosystems — ask the same question, recognise the answer.
- A removed dependency. Note it positively in the summary — the diff is doing the work others won't.
- Internal monorepo packages. They're not third-party.

## The bar

A new dependency is justified when the value it brings — security-critical correctness, real complexity-hiding, broad ecosystem familiarity — outweighs the permanent cost of carrying it. When a built-in or three lines of code would do, the cost wins.
