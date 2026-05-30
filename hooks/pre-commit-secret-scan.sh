#!/usr/bin/env bash
# pre-commit-secret-scan.sh — layered (filename + regex + gitleaks). Exits non-zero on hit.

set -uo pipefail

AUDIT_LOG="${CLAUDE_AUDIT_LOG:-/audit/$(date -u +%F).jsonl}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CWD="$(pwd)"

log_hit() {
  mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || true
  printf '{"ts":"%s","src":"pre-commit","action":"secret-scan-hit","cwd":"%s","layer":"%s","detail":"%s"}\n' \
    "$TS" "$CWD" "$1" "$2" >> "$AUDIT_LOG"
}

# Override path: skip everything if CLAUDE_ALLOW_SECRET_COMMIT=1 (logged as override-used).
if [[ "${CLAUDE_ALLOW_SECRET_COMMIT:-0}" == "1" ]]; then
  mkdir -p "$(dirname "$AUDIT_LOG")"
  printf '{"ts":"%s","src":"pre-commit","action":"secret-scan-override","cwd":"%s","blocked":false}\n' \
    "$TS" "$CWD" >> "$AUDIT_LOG"
  exit 0
fi

staged=$(git diff --cached --name-only --diff-filter=ACM)
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
diff_content=$(git diff --cached --no-color)
for p in "${patterns[@]}"; do
  if echo "$diff_content" | grep -E -- "$p" >/tmp/pat-hit; then
    hit=$(head -1 /tmp/pat-hit | head -c 80)
    log_hit "regex" "$p"
    echo "BLOCKED (regex): pattern '$p' matched staged diff." >&2
    echo "  Matched line (truncated): $hit" >&2
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
