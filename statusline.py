#!/usr/bin/env python3
"""Claude Code status line: context, 5-hour, and weekly usage with color coding."""
import os
import sys
import json
import time

def color_for_pct(pct):
    """Green < 40, yellow < 55, orange < 75, red < 90, bold red >= 90."""
    if pct < 40:
        return "\033[32m"   # green
    elif pct < 55:
        return "\033[33m"   # yellow
    elif pct < 75:
        return "\033[38;5;208m"  # orange (256-color)
    elif pct < 90:
        return "\033[31m"   # red
    else:
        return "\033[1;31m" # bold red

def color_for_ctx_tokens(tokens):
    """Color shift based on absolute context size; ~100k is the rot threshold."""
    if tokens < 25000:
        return "\033[32m"        # green
    elif tokens < 50000:
        return "\033[33m"        # yellow
    elif tokens < 75000:
        return "\033[38;5;208m"  # orange
    elif tokens < 100000:
        return "\033[31m"        # red
    else:
        return "\033[1;31m"      # bold red — in rot territory

RESET = "\033[0m"
DIM = "\033[2m"

def collapse_path(p, max_len=30):
    """Replace $HOME with ~, normalize separators, truncate deep paths."""
    if not p:
        return ""
    p_norm = p.replace("\\", "/")
    home_norm = os.path.expanduser("~").replace("\\", "/")
    if p_norm.lower().startswith(home_norm.lower()):
        p_norm = "~" + p_norm[len(home_norm):]
    if len(p_norm) <= max_len:
        return p_norm
    parts = [s for s in p_norm.split("/") if s]
    truncated = ".../" + "/".join(parts[-2:])
    if len(truncated) <= max_len:
        return truncated
    return ".../" + parts[-1]

try:
    data = json.loads(sys.stdin.read())
except Exception:
    print("statusline: no data")
    sys.exit(0)

# Context window
ctx = data.get("context_window", {})
ctx_pct = ctx.get("used_percentage") or 0
ctx_pct_int = int(ctx_pct)
ctx_tokens = ctx.get("total_input_tokens") or 0

# Rate limits (Claude.ai Pro/Max only)
rl = data.get("rate_limits", {})
five_hr = rl.get("five_hour", {})
seven_day = rl.get("seven_day", {})
five_hr_pct = five_hr.get("used_percentage")
seven_day_pct = seven_day.get("used_percentage")

# Session cost
cost = data.get("cost", {})
session_cost = cost.get("total_cost_usd", 0)

parts = []

# Current working directory (orientation)
cwd = data.get("workspace", {}).get("current_dir") or data.get("cwd")
if cwd:
    parts.append(f"{DIM}{collapse_path(cwd)}{RESET}")

# Context usage — color is driven by absolute tokens (100k is the rot threshold)
c = color_for_ctx_tokens(ctx_tokens)
parts.append(f"{c}ctx:{ctx_pct_int}% ({round(ctx_tokens / 1000)}k){RESET}")

# 5-hour (session-ish) usage
if five_hr_pct is not None:
    p = int(five_hr_pct)
    c = color_for_pct(p)
    resets_at = five_hr.get("resets_at")
    if resets_at is not None:
        remaining = max(0, resets_at - time.time())
        hrs = int(remaining // 3600)
        mins = int((remaining % 3600) // 60)
        if hrs > 0:
            reset_str = f"{hrs}h{mins:02d}m"
        else:
            reset_str = f"{mins}m"
        parts.append(f"{c}5hr:{p}% ({reset_str}){RESET}")
    else:
        parts.append(f"{c}5hr:{p}%{RESET}")
elif session_cost is not None:
    parts.append(f"{DIM}session:${session_cost:.2f}{RESET}")

# Weekly usage
if seven_day_pct is not None:
    p = int(seven_day_pct)
    c = color_for_pct(p)
    parts.append(f"{c}weekly:{p}%{RESET}")

print(" | ".join(parts))
