---
description: Use when about to flip a repo public, before any push to a public repo, when the user says "audit", "go public", "pre-release scrub", "history rewrite for secrets", or any time leaked secrets / proprietary refs / hardcoded paths in git history are a concern. Scans for secrets, proprietary refs, hardcoded paths, large binaries, and gitignore gaps; reports before any push; never flips the repo public.
---

You are running a **pre-public-repo audit** on the current working directory. Your job is to find anything that should not be in a public repo, report it clearly, and (with the user's approval) clean it up via history rewrite where needed. **Never flip the repo public yourself** — that's the user's call after they've reviewed your findings.

## Audit checklist

Run all of these. Report findings as a single structured summary at the end.

1. **Secrets in working tree.**
   - Grep for `password`, `secret`, `api[_-]?key`, `token`, `bearer`, `aws_access`, `client_secret`, private SSH keys (`-----BEGIN`).
   - Look for `.env`, `.env.local`, `credentials.json`, `*.pem`, `*.key` files committed.

2. **Secrets in history.** (More important than working tree.)
   - `git log --all --oneline | head -200` — scan commit messages for accidental secret leaks.
   - `git rev-list --all | xargs git grep -l "secret\|password\|token"` (or equivalent) for occurrences across all commits.

3. **Proprietary references.**
   - Grep for the user's employer / client names, internal hostnames (`*.internal`, `*.corp`, `*.local` if they're company subdomains), internal Slack channel names, JIRA keys, internal product codenames.
   - Ask the user if you're unsure what counts as proprietary — don't guess.

4. **Salary / compensation / PII risk.**
   - Grep for salary numbers, comp ratios, performance review snippets, employee IDs.

5. **Hardcoded absolute paths.**
   - Grep for `C:\Users\`, `/home/`, `/Users/`, `D:\`, `E:\`. Public repos shouldn't carry the author's machine paths.

6. **`.gitignore` gaps.**
   - Confirm the following are ignored: `node_modules/`, `dist/`, `build/`, `.env*`, `*.log`, IDE folders (`.vscode/`, `.idea/`), OS files (`.DS_Store`, `Thumbs.db`), build outputs, `docs/` if generated.
   - Check that nothing currently *tracked* should have been ignored — `git ls-files` cross-referenced against the patterns.

7. **Large binaries.**
   - `git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sort -k3 -n -r | head -20` — identify the biggest blobs in history. Flag anything over 5 MB that isn't legitimately needed.

8. **CI status.**
   - Check `.github/workflows/` for hardcoded secrets, missing `secrets.*` references, broken or stale workflows.

## On findings

For each finding, report:
- **What** was found
- **Where** (file path + line, or commit hash + path)
- **Severity** (critical = secret/PII, high = proprietary, medium = path/binary, low = gitignore gap)
- **Suggested remediation**

If any **critical** finding (secret in history, PII), the only valid remediation is **history rewrite** (`git filter-repo` or interactive rebase). A cleanup commit on top is **not** acceptable — stop and tell the user.

For medium / low findings, propose a single bundled commit that fixes all of them.

## Execution boundary

- After reporting, **wait for user approval** before any history rewrite or force push.
- Never run `git push` (any form) without explicit user confirmation.
- Never call `gh repo edit --visibility public` or equivalent. The user flips public, not you.
