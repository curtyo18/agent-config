# agent-config

Claude Code configuration: coding standards, git hooks, slash commands, and skills.

## What's here

- **standards/** — Code quality rules loaded by `/code-review`: naming, testing, duplication, module depth, dependency discipline, UI preferences.
- **hooks/** — Pre-commit secret scanning (filename, regex, gitleaks).
- **commands/** — Slash commands for code review (`code-review` plus the layered multi-agent `deep-code-review`), release checklists, cloud agent briefs, Chrome extension scaffolding, pre-public-repo audits, and selective context compaction (`context-collector`).
- **skills/** — Agent skills: `idea` (vague → grilled spec → plan), `run-plan` (subagent execution), `to-issues`, `grill-me`, `debug` (root-cause-first investigation).
- **CLAUDE.md** — Global conventions cloned in as `~/.claude/CLAUDE.md`: scope discipline, two-strike rule, git workflow, permission hygiene.
- **settings.json** — Claude Code settings: default model, permission allowlist + default mode, and statusline wiring.
- **statusline.py** — Optional Claude Code status line script showing session usage metrics.
- **gitleaks.toml** — Secret pattern rules for the pre-commit scan.
- **network-allowlist.conf** — Squid ACL entries used by [agent-sandbox](https://github.com/curtyo18/agent-sandbox).

## Using this

Clone into `~/.claude`:

```bash
git clone https://github.com/curtyo18/agent-config.git ~/.claude
```

Or let [agent-sandbox](https://github.com/curtyo18/agent-sandbox) do it automatically on container start.

> **Heads-up on defaults.** `settings.json` ships permissive defaults (`bypassPermissions`,
> `skipDangerousModePermissionPrompt`) tuned for the agent-sandbox container, where the container
> *is* the sandbox. If you clone this standalone onto a host, review `settings.json` first —
> outside the sandbox you'll likely want a stricter `permissions.defaultMode`.

## Status line

`statusline.py` renders a compact, colour-coded session readout in the Claude Code status bar:

![agent-config status line](docs/statusline.png)

Left to right:

- **cwd** — current directory (dimmed; `~` for home, long paths truncated) for orientation.
- **`ctx:N% (Mk)`** — context window used: percentage of the window plus the absolute token count
  (in thousands). Its colour tracks the **absolute tokens, not the percentage** — what degrades a
  session ("context rot") is how many tokens are in play, not how full the window is, so `ctx:45%`
  can already be red if that's ~80k tokens.
- **`5hr:N% (Xh Ym)`** — Claude.ai Pro/Max 5-hour rate-limit usage and time to reset; falls back to
  **`session:$X.XX`** (session cost) when no rate-limit data is present.
- **`weekly:N%`** — Claude.ai Pro/Max 7-day rate-limit usage.

The context colour escalates with absolute size — **red at ~75k, and bold red at ~100k, where
context rot starts to bite** (your cue to compact, summarise, or start a fresh session):

| Context tokens | Colour |
|---|---|
| < 25k | green |
| 25k–50k | yellow |
| 50k–75k | orange |
| 75k–100k | red |
| ≥ 100k | **bold red** (rot territory) |

(The 5-hour and weekly bars use a percentage scale instead: green < 40%, then yellow, orange,
red ≥ 75%, and bold red ≥ 90%.)

## Planning & execution skills

Self-contained — no plugin dependency; clone the repo and they work as-is. `idea` is the front
door (vague idea → grilled spec → numbered plan → handoff menu); `run-plan` executes the plan via
per-task subagent dispatch with two-stage review (or inline); `to-issues` converts it to GitHub
issues instead; `grill-me` (a relentless-interview approach inspired by Matt Pocock) drives the
questioning in `idea`'s shaping and grilling phases and also runs standalone to stress-test a plan
or design. They compose, but each stands alone. (Reimplemented from what the *superpowers* plugin
used to provide.)

## Adapting it

Fork and edit directly. The standards, hooks, and commands are designed to be modified — they represent opinions, not rules.
