# Code duplication

When the same shape of code appears in three or more places, an abstraction is missing or the wrong one. Pragmatism keeps this from becoming dogma — not every textually-similar block is real duplication, and premature abstraction is harder to undo than late abstraction.

## What to flag

- **Same multi-line block in three or more places** — A block of 5+ lines that recognisably encodes one concept (a particular query shape, a particular validation routine, a particular response-formatting sequence) appearing in three or more locations. Propose extraction. *Severity: Important.*
- **Two-place duplication where the second copy creates pressure for a third** — A diff that copy-pastes a non-trivial block to a second location, knowingly setting up future drift. Note it, propose the abstraction now while the shape is clear. *Severity: Minor* until the third copy lands.
- **Drifting duplicates** — Two places that *used to* be the same but have diverged slightly. Either re-converge or document why they're different. *Severity: Important.*
- **Inline literals duplicated across files** — The same string / constant / regex appearing in many places. Even if the code isn't duplicated, the value is — extract to a named constant. *Severity: Minor.*

## What NOT to flag (pragmatism guard)

- Patterns that *look* duplicated but evolve independently — code that answers different questions and is likely to diverge. Forcing them to share is the wrong move.
- Generated code, fixtures, test snapshots, lockfiles.
- Boilerplate that is clearer when explicit (e.g. tight test arrange blocks — see `test-patterns.md`).
- Three short one-liners that happen to share a shape — abstraction would obscure, not clarify.

## The bar

When a reader sees the same shape and immediately recognises it as one concept, the duplication is real and a well-named helper will pay for itself. When the shape is incidental similarity between things that aren't the same idea, leave it alone — three similar lines beat a premature abstraction.
