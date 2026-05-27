---
name: curt-plan
description: Idea → grilled-spec → numbered-plan workflow with an intensity dial. Use when the user says "curt-plan", "/curt-plan", "let's plan this", "shape this idea", "spec it out with grilling", or has a feature idea that needs design before code. Produces a spec at ~/.claude/specs/ and a plan at ~/.claude/plans/, then offers a handoff menu (GitHub issues, cloud primer, local subagents, or hybrid local-prereqs-then-cloud). Don't write implementation code in this skill — the plan file is the deliverable.
---

# curt-plan

Take a vague idea through six phases: intensity gate → idea shaping → grilling (intensity-scaled) → spec → numbered plan → handoff menu. The plan file is the deliverable; do not implement code here.

## Phase 0 — Intensity gate

Read the user's idea. Propose a default 1-10 based on:

- Load-bearing keywords (auth, migration, schema, refactor, architecture, public-facing) → raise
- Vagueness ("something like", "maybe we", "kind of") → raise
- Size hints ("quick", "small", "tiny", "one-off script") → lower
- Reversibility (throwaway script → low; core infra / shared state → high)

Ask exactly: **"I'd put this at a {N}/10. Go with that, or pick another?"** Wait for confirmation. Use the chosen level to scale phases 1 and 2.

The level controls two things:

- **Clarifying-question count:** 1 → 2-3 questions, 5 → 5-7, 10 → exhaust the tree
- **Grilling depth and length:** 1-3 light (one question on the single most load-bearing decision); 4-6 medium (the 2-3 riskiest decisions); 7-10 deep (every branch of the decision tree). Grilling is never skipped — every level gets at least one question.

## Phase 1 — Idea shaping (always run)

Ask clarifying questions one at a time. Count from the intensity scale above. Prefer multiple-choice. Focus: purpose, constraints, success criteria. Stop when you can restate the feature in two sentences without inventing details.

Then propose **2-3 fundamentally different approaches** — not variations. For each:

- One-line description
- Strongest argument for
- Strongest argument against
- Rough cost (lines, files, dependency impact)

Recommend one and explain why. Wait for the user's pick or pushback before continuing.

## Phase 2 — Grilling

Grilling runs at every intensity level. The level scales depth and length, not whether it happens.

**Intensity 1-3 — light.** Identify the single most load-bearing decision in the chosen approach. Ask one question on it, provide your recommended answer, wait for the user. Then move to Phase 3.

**Intensity 4-6 — medium.** Identify the 2-3 riskiest decisions. For each: ask one question at a time, provide your recommended answer, wait. Riskiest = most expensive to reverse, most load-bearing for downstream choices, or most uncertain.

**Intensity 7-10 — deep.** Walk every branch of the decision tree. For each unresolved decision, ask one question, give your recommendation, wait. Do not move on until the branch is resolved.

In all bands: if a question can be answered by reading the codebase, read instead of asking. End the phase when no decisions remain unresolved or the user says "enough".

## Phase 3 — Spec

Summarize the design from phases 1-2 into a spec at `~/.claude/specs/<YYYY-MM-DD>-<slug>-design.md`.

Cover what the feature actually needs, scaled to size — a 200-line feature does not get a 1000-line spec. At minimum touch on: the goal, architecture and components, data flow / interfaces, error handling, and testing strategy. Add an explicit **Out of scope** line so Phase 4's writing-plans skill doesn't pull in deferred work.

**Self-review pass:** scan for placeholders, internal contradictions, ambiguity (any requirement that could be interpreted two ways), and scope creep. Fix inline.

## Phase 4 — Plan

Invoke `superpowers:writing-plans`. Tell it:

1. The spec is at `~/.claude/specs/<YYYY-MM-DD>-<slug>-design.md` (the file just written in Phase 3).
2. Save the plan to `~/.claude/plans/<YYYY-MM-DD>-<slug>-implementation.md` (overrides writing-plans' default `docs/superpowers/plans/` location).

Writing-plans handles the TDD-shaped task structure, file targets, exact commands, and its own self-review pass. Do not write the plan inline.

## Phase 5 — Handoff menu

Report spec path and plan path. Then ask:

**How do you want to execute this?**

- **A) GitHub issues** — invoke the `to-issues` skill to break the plan into independently-grabbable issues
- **B) GitHub issues + cloud primer** — invoke `to-issues`, then `/cloud-prime` to draft a brief for a cloud agent
- **C) Local subagents** — invoke `superpowers:subagent-driven-development` to execute task-by-task in this session
- **D) Hybrid: local prereqs → cloud handoff** — run the tasks that need the local environment via local subagents first, then hand the remainder to a cloud agent via `/cloud-prime`. Best fit for new repos and any plan with a mix of local-bootstrap and pure-code tasks.
- **E) Stop here** — you'll execute separately

Wait for the pick. Invoke the chosen path. Do not start implementing inside this skill regardless of which option is chosen.

### When D (hybrid) is picked

Walk the plan's task list and tag each task as **local** or **cloud-friendly**:

- **Local** — needs files outside the repo (e.g. gitignored handover folders, `~/.config`, env vars), the user's `gh` / npm / SSH auth, repo bootstrap (`git init`, `gh repo create`, initial push), or hardware/browser interaction the user must drive.
- **Cloud-friendly** — pure repo work using repo-relative paths, runnable in a sandbox with stock tools.

Present the proposed split as a short list (e.g. *"Local: T1, T4, T7. Cloud: T2, T3, T5, T6, T8."*). If local tasks are interleaved with cloud tasks in a way that forces the cloud agent to depend on yet-unrun local work, propose either reordering (if dependencies allow) or promoting more tasks to local so the cloud handoff happens at a clean break. Confirm the split before proceeding.

Then: invoke `superpowers:subagent-driven-development` for the local subset. When it reports back done (and the local repo state is pushed to the remote where applicable), invoke `/cloud-prime` with the remaining tasks plus the current repo state for the cloud agent — note in the brief which tasks are already done and what state the agent inherits.

## Dependencies

Phases 0-3 (intensity gate, idea shaping, grilling, spec) are embedded inline — no external deps. Phases 4-5 invoke external tools:

| What | Source | Used by |
|---|---|---|
| `superpowers:writing-plans` | **superpowers plugin** | Phase 4 (plan writing) |
| `to-issues` skill | **Matt Pocock** (`/setup-matt-pocock-skills`) | Phase 5 options A, B |
| `/cloud-prime` slash command | In this repo (`commands/cloud-prime.md`) | Phase 5 options B, D |
| `superpowers:subagent-driven-development` | **superpowers plugin** | Phase 5 options C, D |

If any upstream tool changes shape or disappears, Phase 4 or 5 is what needs to react — phases 0-3 are immune.

## Notes for tinkering

Phases 0-3 (intensity gate, idea shaping, grilling, spec) are in-repo — edit freely without worrying about upstream skill changes. Phase 4 delegates plan writing to `superpowers:writing-plans` because the structure (TDD-shaped tasks, file targets, exact commands, self-review) is well-trodden upstream and not worth maintaining a parallel implementation. Phases 1-2 are the grill-me adaptation that replaces what `superpowers:brainstorming` would otherwise do.
