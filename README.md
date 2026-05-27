# agent-config

Claude Code configuration: coding standards, git hooks, slash commands, and skills.

## What's here

- **standards/** — Code quality rules loaded by `/code-review`: naming, testing, duplication, module depth, dependency discipline, UI preferences.
- **hooks/** — Pre-commit secret scanning (filename, regex, gitleaks) and a session-start audit summariser.
- **commands/** — Slash commands for code review, release checklists, cloud agent briefs, Chrome extension scaffolding, and pre-public-repo audits.
- **skills/** — Agent skills: `idea` (vague → grilled spec → plan), `run-plan` (subagent execution), `to-issues`, `grill-me`, `find-skills`, `write-a-skill`.
- **statusline.py** — Optional Claude Code status line script showing session usage metrics.
- **gitleaks.toml** — Secret pattern rules for the pre-commit scan.
- **network-allowlist.conf** — Squid ACL entries used by [agent-sandbox](https://github.com/curtyo18/agent-sandbox).

## Using this

Clone into `~/.claude`:

```bash
git clone https://github.com/curtyo18/agent-config.git ~/.claude
```

Or let [agent-sandbox](https://github.com/curtyo18/agent-sandbox) do it automatically on container start.

## Adapting it

Fork and edit directly. The standards, hooks, and commands are designed to be modified — they represent opinions, not rules.
