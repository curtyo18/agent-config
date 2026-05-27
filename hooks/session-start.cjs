#!/usr/bin/env node
// session-start.cjs — emits a system-reminder summarising audit-log events since
// the last session ended. Silent if nothing interesting.

const fs = require('fs');
const path = require('path');
const os = require('os');

const STATE_DIR = path.join(os.homedir(), '.claude-state');
const LAST_STAMP = path.join(STATE_DIR, 'last-session-end.txt');
const AUDIT_DIR = '/audit';

const INTERESTING = (event) => {
  if (event.blocked === true) return true;
  if (event.src === 'pre-commit' && event.action === 'secret-scan-hit') return true;
  if (event.src === 'squid' && /^TCP_DENIED/.test(event.action || '')) return true;
  if (event.reason && /unlock-used/.test(event.reason)) return true;
  if (event.src === 'entrypoint' && /failed$/.test(event.action)) return true;
  return false;
};

function loadLastStamp() {
  try { return new Date(fs.readFileSync(LAST_STAMP, 'utf8').trim()); }
  catch { return new Date(0); }
}

function writeLastStamp() {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(LAST_STAMP, new Date().toISOString());
}

function collectEvents(since) {
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86400_000).toISOString().slice(0, 10);
  const candidates = [
    path.join(AUDIT_DIR, `${yesterday}.jsonl`),
    path.join(AUDIT_DIR, `${today}.jsonl`),
  ];
  const events = [];
  for (const file of candidates) {
    if (!fs.existsSync(file)) continue;
    const lines = fs.readFileSync(file, 'utf8').split('\n').filter(Boolean);
    for (const line of lines) {
      try {
        const ev = JSON.parse(line);
        if (new Date(ev.ts) > since && INTERESTING(ev)) events.push(ev);
      } catch { /* skip malformed lines */ }
    }
  }
  return events;
}

const since = loadLastStamp();
const events = collectEvents(since);

if (events.length > 0) {
  const lines = events.slice(0, 20).map(
    (e) => `  - ${e.ts} [${e.src}] ${e.action || ''}${e.reason ? ' (' + e.reason + ')' : ''}`
  );
  const overflow = events.length > 20 ? `\n  …and ${events.length - 20} more (see ${AUDIT_DIR}).` : '';
  const out = [
    `Since your last session, ${events.length} guard-rail / audit event(s) need review:`,
    ...lines,
    overflow,
  ].join('\n');
  // Emit as system-reminder-shaped context. Claude Code reads stdout from
  // SessionStart hooks and prepends it as context.
  process.stdout.write(`<system-reminder>\n${out}\n</system-reminder>\n`);
}

writeLastStamp();
