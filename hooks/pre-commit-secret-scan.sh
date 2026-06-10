#!/usr/bin/env bash
# pre-commit-secret-scan.sh — layered (filename + regex + gitleaks). Exits non-zero on hit.

set -uo pipefail

AUDIT_LOG="${CLAUDE_AUDIT_LOG:-/audit/$(date -u +%F).jsonl}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CWD="$(pwd)"

# JSON-escape a string for safe interpolation into a JSONL field (backslash first, then quote).
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

log_hit() {
  mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || true
  printf '{"ts":"%s","src":"pre-commit","action":"secret-scan-hit","cwd":"%s","layer":"%s","detail":"%s"}\n' \
    "$(json_escape "$TS")" "$(json_escape "$CWD")" "$(json_escape "$1")" "$(json_escape "$2")" >> "$AUDIT_LOG"
}

# Override path: skip everything if CLAUDE_ALLOW_SECRET_COMMIT=1 (logged as override-used).
# Fail closed — the override is only honoured if the audit record is actually written. An
# unwritable audit log must refuse the override rather than allow an untracked bypass.
if [[ "${CLAUDE_ALLOW_SECRET_COMMIT:-0}" == "1" ]]; then
  if ! mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || \
     ! printf '{"ts":"%s","src":"pre-commit","action":"secret-scan-override","cwd":"%s","blocked":false}\n' \
       "$(json_escape "$TS")" "$(json_escape "$CWD")" >> "$AUDIT_LOG" 2>/dev/null; then
    echo "REFUSED (override): CLAUDE_ALLOW_SECRET_COMMIT=1 set but audit log '$AUDIT_LOG' is unwritable." >&2
    echo "  An override that cannot be recorded is not allowed. Fix CLAUDE_AUDIT_LOG and retry." >&2
    exit 1
  fi
  exit 0
fi

staged=$(git diff --cached --name-only --diff-filter=ACMR)
[[ -z "$staged" ]] && exit 0

# === Layer 1: filename filter ===
bad_names_regex='(^|/)(\.env(\..+)?|.*\.pem|.*\.key|.*\.pfx|id_rsa[^/]*|.*\.kdbx|credentials\.json|secrets\.ya?ml)$'
if echo "$staged" | grep -E -- "$bad_names_regex" | head -1 >/tmp/bad-name; then
  hit=$(cat /tmp/bad-name)
  log_hit "filename" "$hit"
  echo "BLOCKED (filename): staged file '$hit' matches credential filename pattern." >&2
  echo "  Override: CLAUDE_ALLOW_SECRET_COMMIT=1 git commit ..." >&2
  exit 50
fi

# === Layer 2: pattern regex on staged diff ===
patterns=(
  'sk_live_[a-zA-Z0-9]{20,}'
  'sk_test_[a-zA-Z0-9]{20,}'
  'ghp_[A-Za-z0-9]{30,}'
  'github_pat_[A-Za-z0-9_]{40,}'
  'AKIA[0-9A-Z]{16}'
  'sk-ant-[A-Za-z0-9_\-]{30,}'
  '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
  'aws_secret_access_key\s*=\s*[A-Za-z0-9/+]{40}'
)
# Scan added lines only — exclude removed/context lines and the +++ file header — so editing a
# secret *out* of a kept file is not blocked (that's the remediation, not the leak). The header
# exclusion anchors on the trailing space ('+++ b/path') so an added *content* line that happens
# to start with '++' (which appears as '+++...' in the diff) is still scanned, not dropped.
added_lines=$(git diff --cached --no-color | grep '^+' | grep -v '^+++ ')
for p in "${patterns[@]}"; do
  if echo "$added_lines" | grep -E -q -- "$p"; then
    log_hit "regex" "$p"
    # Do not print the matched line — it would leak the secret to stderr/transcript. Report the
    # pattern and the staged file list instead.
    echo "BLOCKED (regex): pattern '$p' matched an added line in the staged diff." >&2
    echo "  Staged files: $(echo "$staged" | tr '\n' ' ')" >&2
    echo "  (Matched text withheld to avoid leaking the secret into the transcript.)" >&2
    echo "  Override: CLAUDE_ALLOW_SECRET_COMMIT=1 git commit ..." >&2
    exit 51
  fi
done

# === Layer 3: gitleaks full scan ===
if command -v gitleaks >/dev/null; then
  if ! gitleaks protect --staged --no-banner --redact \
      --config "${CLAUDE_GITLEAKS_CONFIG:-$HOME/.claude/gitleaks.toml}" 2>/tmp/gl.err; then
    log_hit "gitleaks" "$(cat /tmp/gl.err | head -3 | tr '\n' ';' )"
    echo "BLOCKED (gitleaks): see output above." >&2
    cat /tmp/gl.err >&2
    echo "  Override: CLAUDE_ALLOW_SECRET_COMMIT=1 git commit ..." >&2
    exit 52
  fi
fi

exit 0
