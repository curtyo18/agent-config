# Coding standards

General code hygiene that doesn't fit a narrower file. Applies regardless of stack. Imported by `/code-review` alongside the other `standards/*.md` files and referenced as a primer from `CLAUDE.md`.

## What to flag

- **Single-letter or cryptic names** — Identifiers like `x`, `tmp`, `data2` outside tight loops or well-established mathematical conventions (e.g. `i`/`j` in a numeric loop, `e` in a one-line catch). Suggest a descriptive name. *Severity: Minor.*
- **Stuttering names** — `userUser`, `getUserUser()`, `OrderOrderRepository`. Almost always a sign of a leaky abstraction or copy-paste. *Severity: Minor.*
- **Comments that restate the code** — `// increment i`, `// return result`. Delete them. Comments earn their place by explaining *why*, hidden constraints, or surprising invariants. *Severity: Minor.*
- **Stale or aspirational comments** — Comments that describe behavior the code no longer has, or "TODO: handle X" with no ticket reference and no plan. Either fix or delete. *Severity: Important.*
- **Functions doing more than one thing** — A function above ~60 non-test lines that mixes parsing + business logic + I/O. Suggest extraction by responsibility, not by line count. *Severity: Important.*
- **Dead code** — Newly-introduced functions, exports, branches, or constants that aren't reachable from any production or test path in the same diff. *Severity: Important.*
- **Magic numbers** — Numeric literals outside `0`, `1`, `-1`, and common HTTP statuses, appearing without a named constant. Especially load-bearing in retry counts, timeouts, batch sizes, percentage thresholds. *Severity: Minor.*
- **Silent catches** — `try { ... } catch { /* nothing */ }` or catches that swallow the underlying error without logging, rethrowing, or recovering deliberately. *Severity: Important.*
- **Stack-losing rethrows** — `catch (e) { throw new Error(e.message); }` loses the underlying stack trace. Prefer rethrowing the original, or wrapping with `cause: e` where the language supports it. *Severity: Important.*

## What NOT to flag (pragmatism guard)

- One-letter loop indices in tight numeric loops, or single-letter math variables in code that mirrors a textbook formula.
- A long function that genuinely does one thing (e.g. a state-machine reducer with one case per state — the length is essential complexity).
- Framework-imposed boilerplate (e.g. React component prop destructuring, ORM model decorators) — not duplication, not magic.
- Comments that explain a non-obvious *why*, even if the *what* could be inferred — leave them.

## The bar

A reader of average experience should be able to read a function and answer "what does it do?" without scrolling, "why does it do it this way?" without leaving the file, and "where would I add a related thing?" without reading the rest of the codebase. When code violates one of these in a way a small change can fix, it's a finding.
