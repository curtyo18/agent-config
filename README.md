# agent-config

Claude Code configuration: coding standards, git hooks, slash commands, and skills.

## What's here

- **standards/** — Code quality rules loaded by `/code-review`: naming, testing, duplication, module depth, dependency discipline, UI preferences.
- **hooks/** — Pre-commit secret scanning (filename, regex, gitleaks).
- **commands/** — Slash commands for code review, release checklists, cloud agent briefs, Chrome extension scaffolding, and pre-public-repo audits.
- **skills/** — Agent skills: `idea` (vague → grilled spec → plan), `run-plan` (subagent execution), `to-issues`, `grill-me`, `debug` (root-cause-first investigation).
- **statusline.py** — Optional Claude Code status line script showing session usage metrics.
- **gitleaks.toml** — Secret pattern rules for the pre-commit scan.
- **network-allowlist.conf** — Squid ACL entries used by [agent-sandbox](https://github.com/curtyo18/agent-sandbox).

## Using this

Clone into `~/.claude`:

```bash
git clone https://github.com/curtyo18/agent-config.git ~/.claude
```

Or let [agent-sandbox](https://github.com/curtyo18/agent-sandbox) do it automatically on container start.

## Planning & execution skills (self-contained)

This config used to depend on the **superpowers** plugin for its planning and execution workflows. Those have been reimplemented in-house as plain skill files, so there is no plugin dependency — clone the repo and the skills work as-is:

| What superpowers provided | Replaced by |
|---|---|
| `writing-plans` | `skills/idea` — phase 4 embeds the plan-writing process inline (`idea/PLAN-WRITING.md`) |
| `subagent-driven-development` / `executing-plans` | `skills/run-plan` — per-task subagent dispatch with two-stage review, or inline mode |
| `brainstorming` | `skills/grill-me` + `idea` phases 1–2 |

`grill-me` is a standalone adaptation of the relentless-interview idea, originally inspired by Matt Pocock: it drives the questioning in `idea`'s shaping and grilling phases, and can also be run on its own to stress-test any plan or design until the decision tree is resolved. `idea` is the front door (vague idea → spec → numbered plan → handoff menu); `run-plan` executes the resulting plan; `to-issues` converts it to GitHub issues instead. The three compose, but each also stands alone.

## Adapting it

Fork and edit directly. The standards, hooks, and commands are designed to be modified — they represent opinions, not rules.
