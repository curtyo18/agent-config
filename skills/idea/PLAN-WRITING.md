# Phase 4 — Plan Writing

Announce: "Writing plan for `<feature>`."

## Before Writing Tasks

**Scope check:** if the spec covers multiple independent subsystems, suggest splitting into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

**Map file structure first:** list every file to be created or modified and its single responsibility before writing any task. This is where decomposition decisions are locked in.

## Task Granularity

Each task is bite-sized (2–5 min per step):
1. Write the failing test
2. Run it — confirm it fails with the expected error message
3. Write minimal implementation to make it pass
4. Run it — confirm it passes
5. Commit

## Plan Failures — Never Write These

- `TBD`, `TODO`, `implement later`, `fill in details`
- `Similar to Task N` — always repeat the code; tasks may be read out of order
- Steps that describe what to do without showing code
- `Add appropriate error handling` without showing the handler
- References to types or functions not defined anywhere in the plan

## Every Task Must Include

- Exact file paths (no `path/to/file` placeholders)
- Complete code blocks — no partial snippets
- Exact CLI commands with expected output
- Type names, method signatures, and property names consistent across all tasks — a name used differently in Task 3 vs Task 7 is a bug in the plan

## Plan Header (required on every plan)

```markdown
# [Feature Name] Implementation Plan

**Goal:** [one sentence]
**Architecture:** [2–3 sentences]
**Tech Stack:** [key technologies and libraries]
```

## Self-Review Pass

After writing all tasks:
1. **Spec coverage** — skim each section of the spec. Can you point to a task that implements it? List any gaps and add tasks.
2. **Placeholder scan** — search for any plan failure pattern above. Fix every instance.
3. **Type consistency** — do all type names, method signatures, and property names match across tasks?

Fix inline. No need to re-review after fixing.
