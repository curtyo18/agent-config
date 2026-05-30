## Scope discipline

Stay inside the boundary of what was asked.

- Do **not** remove or alter existing UX behaviors (animations, dimming, hover states, pagination, keyboard shortcuts, default values) without explicit approval. If you think a behavior is wrong, *flag it* — don't quietly delete it.
- Do **not** refactor adjacent code, rename unrelated variables, "clean up" comments, or reorder imports while doing an unrelated task. A bug fix doesn't need surrounding cleanup.

If a change you want to make falls outside the request, say so and ask first.

## Two-strike rule

If your first fix doesn't fully work, try one more focused attempt. If that doesn't work either, **stop patching**.

- Summarize what's failing and *why your model of the problem appears to be wrong*.
- Propose 2–3 fundamentally different approaches (not variations of the failing one).
- Wait for direction before continuing.

This rule exists because patching a flawed model with offset hacks always loses to stepping back and rethinking the underlying coordinate system / data flow / abstraction.

## Git workflow defaults

- **Single commit per logical change.** Stage all related files together (`.gitignore`, code, tests, docs, frontmatter) in one commit. Don't follow a feature commit with a "fix gitignore" or "fix lint" cleanup commit — amend or restage before pushing.
- **History rewrite for secrets / proprietary refs.** If you discover a leak in past commits, rewrite history (`git filter-repo`, interactive rebase) — don't add a "remove secret" cleanup commit. Cleanup commits don't actually remove the secret from history.
- **No `--force-push` to a shared branch** without explicit confirmation. To `main` on a public repo: never without confirmation.

## Permission-prompt hygiene

Before asking the user to approve a Bash command (or after a tool call is denied), pause and consider safer paths:

1. **Built-in tool first.** If the goal is reading/listing/searching files, use `Read`, `Glob`, or `Grep` instead of `cat`/`ls`/`find`/`grep`. If the goal is editing, use `Edit`/`Write`. These never prompt.
2. **Narrow the command.** A wide invocation (`find / ...`, `npm run *`, scripts that touch many things) is more likely to be denied. Re-scope to a specific path, file, or exact subcommand the user has likely allowlisted.
3. **Check if it's a solved problem.** If a command is failing or needs elevated rights, briefly use `WebSearch` / `WebFetch` to look for an established safer pattern (read-only flag, dedicated CLI subcommand, environment-variable approach) before asking the user to broaden permissions.
4. **Only then ask.** If you still need the user, propose the *narrowest* form and explain why no safer alternative exists.

Do not retry the same denied command verbatim. Treat a denial as a signal to rethink, not to repeat.

> **Caveat — sandboxed / skip-permissions runs:** When Claude runs with `--dangerously-skip-permissions` (e.g. inside the agent-sandbox container), Bash commands never prompt — the container's guard rails (network allowlist, command wrappers, secret-scan hook) are the safety net instead. There, "it might get denied" no longer applies, so steps 2–4 are about *scope discipline and intent* (narrow, deliberate commands), not dodging a prompt.

## Self-heal on guard-rail hits

When a wrapper or hook produces a non-zero exit explaining a blocked action (network deny, gh wrapper block, pre-commit secret-scan hit), treat the structured error as guidance to try alternatives. Specifically:

1. Read the error message. The wrapper tells you which rule fired and how to override.
2. Try up to **3** different legitimate approaches that don't trip the same guard. Examples: use a different package mirror, vendor the dependency, propose the destructive change as a TODO in a comment, move secrets to env vars and add `.env.example`.
3. Only after 3 alternatives fail, surface the failure in the chat: list what was tried, what each error was, and ask for an explicit unlock or guidance. Do not silently retry the same blocked operation.

## Host clipboard access

You're inside a Linux container; the user's clipboard lives on Windows. Two commands bridge them:

- `clip` — pipe stdin into the user's Windows clipboard. Use when the user asks you to copy something, when you generate a URL / snippet / list they'll need to paste elsewhere, or when output is more useful in their clipboard than in the chat.
  ```bash
  echo "the thing" | clip
  git log --oneline -10 | clip
  ```
- `paste` — print the current Windows clipboard to stdout. Use when the user says "I've copied X, use it" or pastes a vague reference.
  ```bash
  url=$(paste)
  paste > /tmp/pasted-input.txt
  ```

Both are one-shot. `clip` overwrites whatever was on the clipboard; offer first when the user might lose something they had copied. `paste` returns the clipboard as-is at the moment you call it — re-call if it might have changed.

## Dev server ports

When starting a local dev server (Python `http.server`, vite, `node` http, anything that listens for browser traffic), bind to a port in the range **8000–8099**. The container only publishes that range to the host, so any other port won't be reachable from a browser on the host machine.

Default to **8000**. If something is already on 8000, try 8001, 8002, etc. — don't reach for 3000 / 5173 / 8080 even if a tool defaults there; explicitly override.

When telling the user where to open the server, use `http://localhost:<port>/` — the published range is bound to 127.0.0.1 on the host, so localhost in their browser hits the container.

## Code quality standards

Detailed rules live in `standards/`. Read the relevant file when a task touches its concern; load them all when running `/code-review`.

- **General code hygiene** — naming, comments, function size, dead code, magic numbers, error handling — `standards/coding-standards.md`
- **Test patterns** — what good tests look like; what to flag — `standards/test-patterns.md`
- **Code duplication** — when repetition crosses the bar into a missing abstraction — `standards/code-duplication.md`
- **Deep modules** — favour small interfaces hiding real complexity; flag shallow wrappers — `standards/deep-modules.md`
- **Dependency discipline** — when to add, when to refuse, when to remove — `standards/dependency-discipline.md`
- **Frontend stack picks and code style** — what to reach for per category (static site, dashboard, SPA, extension), dark-only mode policy, component-library trigger, and review-time code rules — `standards/ui-prefs.md`

For audits, run `/code-review` to load all of these and dispatch a reviewer subagent. See `commands/code-review.md`.
