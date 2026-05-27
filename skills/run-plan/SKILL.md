---
name: run-plan
description: Execute an implementation plan task-by-task. Use when running a numbered plan produced by /idea or any implementation plan file.
---

# run-plan

Execute an implementation plan. If mode is not specified, ask at the start:

- **Mode 1: Subagent dispatch** — fresh agent per task with two-stage review (recommended)
- **Mode 2: Inline** — execute steps in this session

## Mode 1: Subagent Dispatch

1. Read the plan file once. Extract ALL tasks with full text and context. Create a checklist.
2. For each task:
   - Select model based on task type (see Model Selection).
   - Dispatch implementer subagent with the full task text. Subagent never reads the plan file itself — task text is passed directly in the prompt.
   - Handle status code response (see Status Codes).
   - Dispatch spec compliance reviewer → loop until passes.
   - Dispatch code quality reviewer → loop until passes.
   - Mark task complete. Move to next.
3. After all tasks complete: dispatch a final full-codebase code reviewer.
4. Never dispatch multiple implementer subagents in parallel.
5. Never start on `main`/`master` without explicit user consent.

## Mode 2: Inline

1. Load the plan. Raise any concerns before starting.
2. Execute each task one at a time: follow steps exactly → run each verification → mark complete.
3. Stop immediately when blocked, a test fails, or an instruction is unclear. Ask; never guess.
4. Recommend Mode 1 if the environment supports subagents.

## Model Selection

| Task type | Model |
|---|---|
| Mechanical — 1–2 file changes, no cross-cutting concerns | Haiku |
| Multi-file integration, moderate complexity | Sonnet |
| Architecture decisions, review tasks | Opus |

## Status Codes (Mode 1)

| Code | Response |
|---|---|
| `DONE` | Proceed to spec review |
| `DONE_WITH_CONCERNS` | Proceed to spec review; surface concerns to user after review passes |
| `NEEDS_CONTEXT` | Provide context; re-dispatch same task |
| `BLOCKED` | Surface to user; wait for direction before continuing |

## Review Order

Spec compliance review **must** pass before code quality review starts. The spec reviewer checks: does the implementation match the plan's requirements? The code quality reviewer checks: is the code well-written? Never reverse this order.
