---
name: debug
description: Find the root cause before proposing any fix — reproduce, read the real error, gather evidence at each component boundary, then trace to the source. Use when hitting a bug, test failure, or unexpected behaviour.
---

# debug

No fix until you can name the root cause in one sentence. A fix proposed before that is a guess, and guesses stacked on a wrong mental model compound into worse bugs. This skill owns the **investigation**; the two-strike rule in `CLAUDE.md` owns what to do when a fix fails.

Work the problem in order — don't jump to step 5.

## 1. Read the actual error

The full message, stack trace, and exit line — not a paraphrase from memory. Note exact paths, line numbers, and codes. The cause is often stated outright; a stale-config bug can be one `couldn't find remote ref` line sitting in a log.

## 2. Reproduce it

Know the exact trigger and that it fires every time. If it's intermittent, gather more data before theorising — you can't test a fix against a moving target.

## 3. Gather evidence at each boundary

In a multi-part system (launcher → script → container → service), check what crosses each seam: what goes in, what comes out, what config/env propagates. Find the seam where good input becomes bad output **before** touching any code. This is the step that pays for itself — it turns "rebuild and pray" into a located fault.

## 4. Trace to the source

Follow the bad value back up the chain to where it originates. Fix it there, not where the symptom surfaced.

## 5. State it, then test one thing

Write the root cause as one sentence: "X happens because Y." If you can't, you're not ready to fix. Then change exactly one thing to confirm it — one variable at a time.

When a fix doesn't work, stop and hand off to the two-strike rule: one more focused attempt, then rethink the model rather than piling on patches.
