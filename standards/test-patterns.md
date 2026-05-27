# Test patterns

Test review rules. Tests are code; they earn their place by giving confidence in behavior. Verbose, copy-pasted, or implementation-coupled tests slow change without catching bugs.

## What to flag

- **Tests that don't assert** — A test that exercises a code path but has no `expect` / `assert` / equivalent against the outcome. The test only catches throws; everything else passes silently. *Severity: Critical.*
- **`.skip` / `.todo` / `xit` introduced in the diff** — Disabled tests added without an explanation, ticket reference, or clear reason. Disabled tests rot. *Severity: Important.*
- **New branches with no test** — A diff that adds an `if` / `else` / `switch case` / new exported function but no test exercising it. Pure helpers are always testable; no excuse there. *Severity: Important.*
- **Hand-rolled retries or `sleep`s to mask flakes** — `await sleep(500)` or a `for (let i=0; i<5; retry)` wrapper added to make a test stop failing. The flakiness is the finding, not the workaround. *Severity: Important.*
- **Mocking what should be integration-tested** — Mocking the database, a real HTTP service the code-under-test owns the contract for, or filesystem behavior when an integration test is feasible. Mocking should stop at the boundary of the system under test. *Severity: Important* (unless the diff calls it out as a deliberate choice).
- **Tests asserting implementation detail** — Assertions on private method calls, internal state, or call counts where a behavior-level assertion was possible. Couples tests to refactors. *Severity: Important.*
- **Verbose / slop tests** — Test bodies with long arrange blocks repeated across cases, or assertion sprawl that obscures what's being tested. Suggest shared setup helpers (carefully — see pragmatism guard). *Severity: Important.*

## What NOT to flag (pragmatism guard)

- Tight, explicit arrange blocks where shared setup *would* hide what each test depends on. Some duplication is clarifying.
- A `.skip` with a clear inline comment pointing to a known issue and a tracking reference.
- A test that asserts on a specific output shape because the shape *is* the contract (e.g. API response, file format).
- Mocks at true system boundaries (third-party APIs the diff doesn't own).

## The bar

A test exists to catch a regression. If it asserts nothing, it catches nothing. If it asserts implementation, it catches refactors but not bugs. If it can be made deterministic, it shouldn't need retries. When a test fails one of these, fix the test — don't paper over it.
