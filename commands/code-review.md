---
description: Use to audit a diff against the agent-config code-quality standards before merge or push. Loads all standards/*.md rule files, then dispatches a reviewer subagent with the diff and the rules. Takes optional positional args `$1`=BASE_SHA `$2`=HEAD_SHA; defaults to origin/main and HEAD.
---

You are running a **code-quality review** against the agent-config standards. Your job is to:

1. Resolve the diff range.
2. Detect whether the `standards/` rule files are reachable.
3. Inline all six rule files into a reviewer prompt.
4. Dispatch a reviewer subagent (`Agent` tool, `general-purpose` type) and surface its report inline.

## Step 1 — Resolve the diff range

Parse positional arguments:
- `BASE` = `$1` if provided, otherwise `origin/main`.
- `HEAD` = `$2` if provided, otherwise `HEAD`.

Resolve to commit SHAs:
```bash
BASE_SHA=$(git rev-parse "$BASE" 2>/dev/null)
HEAD_SHA=$(git rev-parse "$HEAD" 2>/dev/null)
```

If either resolution fails, report which ref didn't resolve and stop.

## Step 2 — Detect rule files

Locate the `standards/` folder. Prefer the repo-relative path `standards/`; fall back to `~/code/agent-config/standards/` if the current repo doesn't have its own copy.

If neither path contains the six expected files (`coding-standards.md`, `test-patterns.md`, `code-duplication.md`, `deep-modules.md`, `dependency-discipline.md`, `ui-prefs.md`), tell the user:

> The agent-config code-quality standards files aren't reachable from this repo. Either (a) cd into a repo that has `standards/`, (b) symlink it from your agent-config checkout, or (c) clone agent-config and point at it explicitly.

Then stop.

## Step 3 — Check the diff is non-empty

```bash
git diff --stat "$BASE_SHA".."$HEAD_SHA"
```

If the diff is empty, report "Nothing to review between `$BASE` and `$HEAD`" and stop.

## Step 4 — Read all rule files

Use the `Read` tool to load each of:
- `standards/coding-standards.md`
- `standards/test-patterns.md`
- `standards/code-duplication.md`
- `standards/deep-modules.md`
- `standards/dependency-discipline.md`
- `standards/ui-prefs.md`

Hold their content for inlining into the reviewer prompt.

## Step 5 — Capture the diff

```bash
git diff "$BASE_SHA".."$HEAD_SHA"
```

If the full diff is enormous (>2000 lines), capture `git diff --stat` plus the per-file diffs for any file the user has flagged in the args (none, by default); otherwise inline the whole diff.

## Step 6 — Dispatch the reviewer subagent

Use the `Agent` tool with:
- `subagent_type: "general-purpose"`
- `description: "Code review against agent-config standards"`
- `prompt:` the template below, with `{BASE_SHA}`, `{HEAD_SHA}`, `{RULE_FILES}`, and `{DIFF}` substituted.

### Reviewer prompt template

```
You are a Senior Code Reviewer auditing a diff against a known set of code-quality standards.

## Rule files (load-bearing — read these first, then review)

{RULE_FILES}

(Each rule file declares severities. Use those severities verbatim in your findings.)

## Diff under review

**Base:** {BASE_SHA}
**Head:** {HEAD_SHA}

```diff
{DIFF}
```

## What to check

Walk each rule file. For each rule that the diff plausibly touches, ask: does the diff comply? If not, that's a finding. Categorize using the severity the rule declares (Critical / Important / Minor). Acknowledge what's done well before listing issues — accurate praise earns trust for the rest of the feedback.

If you see issues *not* covered by the rule files (security, correctness, broken behavior, obvious bugs), include them too. Don't make up rules that aren't in the files for stylistic preferences — the rule files are the boundary of stylistic opinion.

## Output format

### Strengths
[Specific positives, with file:line citations.]

### Issues

#### Critical (Must Fix)
[Each: file:line — what is wrong — why it matters — how to fix.]

#### Important (Should Fix)
[Same shape.]

#### Minor (Nice to Have)
[Same shape.]

### Assessment

**Ready to merge?** [Yes | No | With fixes]
**Reasoning:** [1–2 sentences.]

## Critical rules

- Cite file:line for every finding. Vagueness is not allowed.
- Use the severity the rule file declared, not your own scale.
- Don't say "looks good" without checking. Don't mark nitpicks as Critical.
- If you find issues with a *rule itself* (rule contradicts another rule, rule is unenforceable from a diff), say so in a final "Notes on the rule files" section — don't penalize the diff for it.
```

## Step 7 — Return the report

When the subagent returns, surface its report inline. Do not summarise it away. The user wants the full Strengths / Issues / Assessment shape.

## Notes for the operator (you)

- This command does not write files, push, or merge. It only reports.
- If the reviewer is wrong, push back with technical reasoning — same as `superpowers:requesting-code-review`.
- For lighter generic reviews, `superpowers:requesting-code-review` continues to work and is unaffected by this command.
