---
name: to-issues
description: Break a plan into GitHub issues. Use when converting an implementation plan into independently-grabbable GitHub issues.
---

# to-issues

Convert an implementation plan into GitHub issues published via `gh issue create`.

## Steps

1. **Parse** — identify tasks and dependencies from the plan.
2. **Slice** — each issue should be a vertical slice: touches every layer end-to-end, demoable independently.
3. **Draft** — present a numbered list to the user for approval:
   ```
   1. Title — blocked by: none
   2. Title — blocked by: #1
   ```
4. **Revise** — iterate on granularity and dependencies until approved.
5. **Publish** — create issues in dependency order (blockers first so their numbers exist before being referenced).

## Issue template

~~~markdown
## What to build
[description of end-to-end behaviour]

## Acceptance criteria
- [ ] criterion

## Blocked by
- #N (or "none")
~~~

## Notes

- One `gh issue create` per issue; do not batch.
- If `gh issue create` fails for one issue, report it and continue with the rest.
- Avoid specific file paths and code snippets in issue bodies — they go stale. Exception: a type shape or state machine that encodes a decision more precisely than prose.
