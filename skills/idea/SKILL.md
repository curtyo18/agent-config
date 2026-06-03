---
name: idea
description: Take a vague idea through intensity-scaled grilling to a spec and implementation plan. Use when a user has an idea, feature request, or problem they want to think through and plan.
---

# idea

Takes a vague idea through five phases: intensity gate → idea shaping → grilling → spec + plan → handoff. The plan file is the deliverable; never implement code inside this skill.

## Phase 0 — Intensity Gate

Read the idea. Propose a default 1–10 based on:
- Load-bearing keywords (auth, migration, schema, refactor, architecture, public-facing) → raise
- Vagueness ("something like", "maybe we", "kind of") → raise
- Size hints ("quick", "small", "tiny", "one-off") → lower
- Reversibility (throwaway script → low; core infra / shared state → high)

Ask exactly: **"I'd put this at a {N}/10. Go with that, or pick another?"** Wait for confirm. Use chosen level to scale phases 1 and 2.

## Phase 1 — Idea Shaping

Ask clarifying questions one at a time. Count scales with intensity: 1 → 2–3 questions, 5 → 5–7, 10 → exhaust the tree. Prefer multiple-choice. Stop when you can restate the idea in two sentences without inventing details.

Propose **2–3 fundamentally different approaches** — not variations. For each: one-line description, strongest argument for, strongest argument against, rough cost (lines, files, dependencies). Recommend one and explain why. Wait for pick or pushback before continuing.

## Phase 2 — Grilling

Always runs regardless of intensity level.

- **1–3 (light)** — identify the single most load-bearing decision. One question with recommended answer. Wait. Move to phase 3.
- **4–6 (medium)** — identify the 2–3 riskiest decisions (most expensive to reverse, most uncertain). One question each with recommendation. Wait between each.
- **7–10 (deep)** — walk every branch of the decision tree. One question per unresolved decision, give recommendation, wait. Done when no decisions remain or user says "enough".

If a question can be answered by reading the codebase, read instead of asking.

## Phase 3 — Spec and Save Location

Before writing the spec, ask where to save:

**A) Home dir** — `~/.claude/specs/` and `~/.claude/plans/`. Informal, untracked.
**B) Current repo** — use convention detection (see below).
**C) Other path** — user supplies base path.

**Convention detection for option B:**
1. Read the repo's CLAUDE.md for an explicit plans/specs convention.
2. If none, look for existing `plans/`, `specs/`, `docs/plans/`, or `docs/specs/` directories.
3. If found, use them.
4. If not found, check `.gitignore` for a suitable ignored folder (`scratch/`, `local/`, `.local/`). Use it if found.
5. If still nothing, add `/.idea-scratch/` to `.gitignore` and use that as the base.

Spec → `<base>/specs/YYYY-MM-DD-<slug>-design.md`
Plan → `<base>/plans/YYYY-MM-DD-<slug>-implementation.md`

Write the spec now. Cover: goal, architecture, components, data flow/interfaces, error handling, testing strategy, and an explicit **Out of scope** section. Scale length to complexity.

Self-review before saving: scan for placeholders, internal contradictions, ambiguity, scope creep. Fix inline.

## Phase 4 — Plan

**REQUIRED:** Follow `PLAN-WRITING.md` in this skill directory for the plan writing process.

## Phase 5 — Handoff

Report spec path and plan path. Ask:

**How do you want to execute this?**

- **A) GitHub issues** — invoke `to-issues`
- **B) GitHub issues + cloud primer** — invoke `to-issues`, then `/cloud-prime`
- **C) Local subagents** — invoke `run-plan` (subagent dispatch mode)
- **D) Hybrid: local prereqs → cloud** — tag each task as local or cloud-friendly; run local tasks via `run-plan`; hand remainder to `/cloud-prime` with a brief noting which tasks are done and what state the agent inherits
- **E) Stop** — execute separately

Wait for pick. Invoke the chosen path. Do not implement code regardless of which option is chosen.
