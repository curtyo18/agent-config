---
description: Selective alternative to /compact. Scans the live context, buckets it, recommends a keep-set you can accept or override, then writes a curated snapshot to /tmp/context-collector/<timestamp>-<slug>.md for resuming in a fresh session. Temp-file only; does not evict tokens from the current session.
---

You are running **Context Collector** — a selective, interactive alternative to `/compact`. Unlike `/compact`, you do **not** evict tokens from this session. You produce a curated **context snapshot** the user carries into a fresh session.

The current session is treated as disposable after this runs.

Work through the four steps below in order. Do not skip the user confirmation in Step 2.

## Step 1 — Scan the live context

Review everything currently in your context window and sort it into these buckets. **Only keep a bucket if it actually has content** — omit empty ones entirely. Use these exact bucket names and order:

1. **Decisions** — choices locked in during the conversation.
2. **Files** — paths read or edited, each with a one-line relevance note.
3. **Open tasks** — the live to-do / next-steps state.
4. **Code / diffs** — actual chunks of code produced or changed.
5. **Constraints & preferences** — rules the user gave.
6. **Key facts / findings** — things discovered.
7. **Commands** — shell commands run and output that matters.
8. **Errors / debugging state** — current failures being chased.

You can only see the **live context window**. If the session was compacted or content scrolled out earlier, it is gone — do not invent it. If there is almost nothing meaningful in context, say so plainly and ask whether to snapshot anyway or abort; do not fabricate buckets.

## Step 2 — Present a numbered list with a recommendation

Print all detected items as a **numbered markdown list grouped by bucket**. Number items continuously across buckets (1, 2, 3, …) so the user can reference any item by a single number. Mark your recommended items with a `✓`.

After the list, add a final line:

`**Recommended keep:** 1, 2, 5, 7` (the numbers you'd keep — your own best assessment of what matters).

Then ask: *"Accept the recommended set, or give me the numbers to keep (e.g. 'keep 1, 5, 6, 7')?"*

Wait for the user. Interpret their reply:
- Acceptance ("go", "looks good", "yes") → use the recommended set.
- Explicit numbers / ranges ("1, 5-7") → use exactly those.
- Exclusions ("drop the debugging stuff") → start from recommended and remove.
- Abort / keep nothing ("forget it", "cancel", "none") → stop here; write no file.
- Ambiguous ("keep the important stuff") → ask one clarifying question; do not guess.

## Step 3 — Write the snapshot

Ensure the directory exists and capture a real timestamp from the shell (do **not** guess the time):

```bash
mkdir -p /tmp/context-collector
ts=$(date +%Y%m%d-%H%M%S)
```

Filename: `/tmp/context-collector/<ts>-<slug>.md`, where `<slug>` is the kebab-case form of the short title you pick for this snapshot (derive the title once, then slugify it — keep the two consistent). Use the exact `$ts` value for **both** the filename and the `**Captured:**` field below so they always match.

Write the file in this **hybrid format** — a narrative preamble followed by structured buckets:

```markdown
# Context Snapshot — <short title>

> **You are resuming prior work.** This is a curated context snapshot, not a full
> transcript. Read it, orient from the Situation below, then continue from Open tasks.
> Captured from visible context only — anything compacted/scrolled out earlier is not here.

**Captured:** <timestamp>  ·  **Source slug:** <slug>

## Situation
<2–3 sentence narrative: where we are, what we're doing, what's next>

<then ONE section per kept bucket, in the standard order above, using the standard
bucket headings. OMIT any bucket with no kept items. Render Open tasks as
`- [ ]` checkboxes. Render Code / diffs in fenced code blocks with a language tag.>
```

Rules:
- The bootstrap header (the `>` blockquote) and the honesty note (`Captured from visible context only …`) are **always present**, even if the user kept very little.
- Only include buckets that have kept items.
- If the write fails, do **not** claim success — report the error and the intended path.

## Step 4 — Report and offer clipboard copy

Print the full snapshot path. Then offer: *"Copy the path to your clipboard?"*

If the user agrees, pipe it to the clipboard bridge — but only if `clip` is available; otherwise just leave the path printed and say so:

```bash
if command -v clip >/dev/null 2>&1; then
  echo "/tmp/context-collector/<ts>-<slug>.md" | clip
else
  echo "clip not available — path printed above."
fi
```

Finally, remind the user: *"Start a fresh session and point it at this file (e.g. `read /tmp/context-collector/<ts>-<slug>.md`) to continue."*
