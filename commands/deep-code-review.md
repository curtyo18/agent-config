---
description: Thorough multi-agent code audit. Partitions the review surface into domains, runs parallel reviewers, then an independent cross-verification round, then adjudicates before any fix. The heavyweight tier above `/code-review`. Optional args $1=BASE_SHA $2=HEAD_SHA; with no args it reviews the whole repo HEAD.
---

You are running a **deep, layered code review**. This is the thorough-audit tier — use it for security- or correctness-critical code, large surfaces, pre-release hardening, or whenever a single-pass review isn't enough. For a quick single-reviewer pass against a diff, use `/code-review` instead.

## Relationship to `/code-review` (do not duplicate it)

`code-review.md` is the single source of truth for the **rubric**: it locates and loads the six `standards/*.md` rule files, defines the reviewer prompt, the Strengths / Issues (Critical / Important / Minor) / Assessment output shape, and the severity vocabulary. This skill **reuses all of that by reference** and adds only the orchestration layer (domain split → parallel review → cross-verification → adjudication → optional fix tail).

- Do **not** re-list or re-describe the six standards files here — point reviewers at the same `standards/` folder `code-review.md` uses (repo-relative `standards/`, else `~/.claude/standards/`).
- Do **not** invent a new severity scale — use the labels the rule files declare, exactly as `/code-review` does.
- The per-reviewer Strengths / Issues (Critical / Important / Minor) shape below is shared with `/code-review` so the two are interchangeable at the leaf level. The **Assessment** block deliberately differs: here it is area-scoped (the area's health), whereas `/code-review`'s is a single merge verdict — that difference is intended, don't force them identical.

## Step 1 — Scope the review

Decide the surface:
- **No args:** whole repo at HEAD (audit mode).
- **`$1` (and optional `$2`):** the diff `BASE..HEAD`, same resolution as `code-review.md`.

Then size it: list the source files and rough LOC. This drives how many reviewers to dispatch.

## Step 2 — Partition into domains

Split the surface into cohesive domains by **responsibility**, not by file count — each reviewer should own an area it can hold in its head (e.g. "background pipeline", "shared/types/schema/storage", "DSL ops", "UI", "build/seeds", "tests"). Tests usually warrant their own reviewer focused on `test-patterns.md`.

Reviewer count guidance:
- ≲ 2.5k LOC: **3–4 domain reviewers + 1 cross-verifier**.
- larger / security-critical: up to **6 domain + 2 cross**.
Do not over-provision — more agents past the point of coverage is cost, not signal.

## Step 3 — Round 1: parallel domain reviewers

Dispatch the domain reviewers **in parallel** (one `Agent` call per domain, all in a single message), `subagent_type: general-purpose`. Each prompt must be self-contained and include:

- The repo path and a 2–3 sentence description of the system.
- The reviewer's assigned files (explicit list) — and that it may read others for context but only **reports** on its own.
- Instruction to read the six `standards/*.md` files from the standards folder first, and to use the severities they declare verbatim.
- The output format below.
- **Scope guards** (these prevent the most common LLM-review failures):
  - This is an existing project — do **not** recommend wholesale stack/tooling migrations; only the code-level rules apply.
  - **Verify platform/library semantics before labelling anything Critical** (e.g. sandbox origin models, framework guarantees). Over-dramatised security findings are the #1 miscalibration.
  - Cite `file:line` for **every** finding. No vague findings. Don't mark nitpicks Critical.
  - Where feasible, **self-verify** a claim by reading enough surrounding code (or running the toolchain) rather than asserting from pattern-match alone.

### Per-reviewer output format (same as /code-review)
```
### Strengths
[Specific positives with file:line.]
### Issues
#### Critical (Must Fix)
#### Important (Should Fix)
#### Minor (Nice to Have)
[Each: file:line — what is wrong — why it matters — how to fix.]
### Assessment
[1–2 sentences on the area's health.]
```

## Step 4 — Round 2: cross-verification (the load-bearing step)

This is what separates a deep review from a noisy one. Round-1 output is typically ~30% over-scoped: miscalibrated severities, false positives, factually wrong claims, and findings that are unactionable by design. **Never act on round 1 directly.**

Collect all round-1 findings. Split them across **1–2 cross-verifier agents** (parallel). Each verifier independently re-checks each assigned finding against the actual code. For every finding it returns:

- **Verdict:** CONFIRMED / FALSE POSITIVE / PARTIALLY CORRECT
- **Calibrated severity:** Critical / Important / Minor / Not-an-issue
- **Evidence:** the `file:line` it checked and what it actually found
- **Fix difficulty & risk:** trivial / moderate / risky, plus any scope concern (would the fix touch unrelated code?)

Tell verifiers explicitly to:
- Check platform semantics before accepting a "Critical".
- Mark findings **unactionable-by-design** where an architectural constraint makes the "fix" impossible without re-architecting (flag, don't pursue).
- Catch claims that are simply wrong (verify, e.g., encoding/format assumptions rather than trusting the reviewer).

End each verifier with a ranked **worth-fixing-now** list and an explicit **not-worth-fixing** list (false positives / premature abstraction / acceptable as-is).

## Step 5 — Adjudicate (you, in the main thread)

Consolidate the verified findings and decide the fix set yourself — do not delegate the judgement:
- Fix: **Critical + Important** (verified, in scope) + cheap, safe **Minors**.
- Skip: false positives, unactionable-by-design, premature abstractions, and anything outside the requested scope.
- Record, briefly, **which findings were skipped and why** — this is part of the deliverable.

Surface the full picture to the user: strengths, the verified issue list with calibrated severities, what you'll fix, and what you're deliberately not fixing.

## Step 6 — Optional fix tail (gated on explicit go)

Only if the user asked you to fix + ship (and only after they say go for the remote steps):
- Implement in an **isolated worktree**, in focused thematic commits, keeping tests green throughout.
- Add a regression test for each behavioural fix.
- Open a PR, wait for CI green, **merge no-squash**, delete the branch, clean up the worktree.
- Run any UI changes in a browser / RTL before claiming success.

## Operator notes

- Reviews are read-only; isolate only when you start fixing.
- If a reviewer is wrong, push back with technical reasoning — don't implement blindly.
- Conserve cost: cheap model for mechanical domains, capable model for the cross-verifiers and adjudication.
- The cross-verification round is non-negotiable. Skipping it turns this back into a single-pass review with extra steps.
