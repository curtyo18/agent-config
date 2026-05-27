# Deep modules

A *deep* module hides significant implementation behind a small interface; a *shallow* module wraps trivial logic in a layer that adds no abstraction. Length isn't depth. The win is in the interface-to-implementation ratio across the module boundary — small surface, real complexity hidden.

## What to flag

- **Wrapper classes that forward every method** — A class whose every public method calls a single corresponding method on one underlying object, adding nothing. Suggest removal and direct use of the underlying object. *Severity: Important.*
- **Shallow facades** — A service like `UserService.findById(id)` that just calls `db.users.where({ id }).first()` once with no validation, caching, fallback, or domain logic. The layer adds a name but no behavior. *Severity: Important.*
- **Functions mutating their arguments** — A pure-looking function that quietly mutates a passed object. Suggest returning a new value instead. *Severity: Important.*
- **Business logic interleaved with I/O** — A handler that mixes DB queries, HTTP calls, and decision logic such that the pure core can't be extracted and tested directly. Suggest lifting the pure decision logic into a separate function with inputs and outputs only. *Severity: Important.*
- **Module-level mutable state used as an ad-hoc cache** — A `let cache = {}` at module scope with no clear invalidation strategy. Suggest a passed-in cache, or removal if it's only there as a "just in case." *Severity: Important.*
- **Hidden time / randomness inside pure-looking helpers** — A function with no I/O parameter that calls `Date.now()` or `Math.random()` internally, making it untestable without monkey-patching. *Severity: Minor* unless it blocks testing, then *Important*.

## What NOT to flag (pragmatism guard)

- One-line accessors / DTOs / data carriers — these *should* be shallow; the shallowness is the point.
- Wrappers that *do* add value the diff makes visible (logging, retry, auth check, error translation). Even a thin wrapper earns its place if it consolidates a cross-cutting concern.
- Test doubles and seam classes that exist precisely to be shallow at the boundary.
- A class whose methods are all one-liners *because* the heavy lifting is in a well-designed helper underneath — that's a deep helper with a thin interface; fine.

## The bar

When a module hides complexity, the boundary between caller and callee is small relative to what's behind it — readers don't need to look inside to use it well. When a module hides nothing, the boundary is just an extra hop. Flag the second; leave the first alone.
