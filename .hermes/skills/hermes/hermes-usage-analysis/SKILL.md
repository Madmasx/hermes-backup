---
name: hermes-usage-analysis
description: "Use when measuring Hermes token usage, cost, or token burn."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, tokens, usage, cost, metrics, optimization]
    related_skills: [hermes-agent]
---

# Hermes Usage & Token Analysis

How to answer "how many tokens/cost have I used?" and "how do I stop burning tokens?" on a Hermes install.

## When to Use

- User asks how many tokens/cost they've spent, total usage, or "¿cuánto he gastado?".
- User wants to reduce token burn or make each token count.
- User asks for a per-model or per-platform usage breakdown.
- You need exact aggregate numbers (not just the `hermes insights` summary).

## Measuring usage

### 1. `hermes insights` (pretty report, zero effort)

```bash
hermes insights --days 365            # default is 30
hermes insights --source cli          # filter by platform
```

Outputs overview (sessions, messages, tool calls, input/output/total tokens),
per-model breakdown, per-platform breakdown, top tools, top skills, activity
patterns, and notable sessions. This is the fastest path to an answer.

### 2. Query state.db directly (for exact numbers and cost)

The `sqlite3` CLI is often NOT installed. Use Python's stdlib `sqlite3` instead:

```bash
python3 -c "
import sqlite3
c = sqlite3.connect('/home/<user>/.hermes/state.db')
cur = c.cursor()
cur.execute('SELECT name FROM sqlite_master WHERE type=\"table\"')
print([r[0] for r in cur.fetchall()])
"
```

The table of interest is `session_model_usage`. Relevant columns:

| column | meaning |
|---|---|
| `input_tokens` | prompt tokens actually sent (uncached context) |
| `output_tokens` | tokens the model generated |
| `cache_read_tokens` | prompt-cache hits (billed at reduced rate / free) |
| `cache_write_tokens` | cache writes |
| `reasoning_tokens` | reasoning-trace tokens |
| `estimated_cost_usd` | cost estimate (see caveat below) |
| `actual_cost_usd` | real billed cost (0 unless a billing API is wired) |
| `cost_status` | `estimated` / `unknown` / NULL |
| `model`, `billing_provider`, `billing_mode`, `task` | grouping keys (part of PK) |

Aggregate everything:

```sql
SELECT
  SUM(input_tokens), SUM(output_tokens),
  SUM(cache_read_tokens), SUM(reasoning_tokens),
  SUM(estimated_cost_usd), SUM(actual_cost_usd)
FROM session_model_usage;
```

## Interpretation — read this before reporting numbers

- **"Total tokens" from `insights` includes cache_read.** The real spend is
  `input + output`. Report both numbers and label them: input+output vs total-with-cache.
- **`cache_read_tokens` is NOT waste.** It is prompt caching working correctly —
  reused context billed at a fraction of full price (free on Gemini's implicit
  cache). A high cache_read figure is a *good* sign, not a problem.
- **`estimated_cost_usd` is frequently garbage.** Free-tier or mispriced models
  (e.g. `gemini-3.5-flash-lite`) inflate it to absurd values (seen: $153k for
  ~104M tokens). Never quote it as the user's real spend. `actual_cost_usd`
  stays `0.00` unless a usage/billing API is configured.
- Numbers are typically in the tens-to-hundreds of **millions**. When the user
  asks "¿esos son millones o miles?", confirm MILLIONS explicitly.

## Token-reduction levers (config-backed, verified)

Check current values first:
```bash
hermes config get compression
hermes config get agent
hermes config get model
hermes config get memory
```

| lever | key | effect |
|---|---|---|
| Session hygiene | `/new` between unrelated tasks | biggest win; long sessions (500+ msgs) drive most spend |
| Compaction trigger | `compression.threshold` (default 0.5) → 0.35 | compact earlier |
| Turn cap | `agent.max_turns` (default 90) → keep low | force compaction sooner |
| Micro-compact | `compression.micro_compact` → true | defrag small context between turns |
| Proactive prune | `compression.proactive_prune_tokens` (0) → ~8000 | drop huge tool outputs mid-flight |
| Reasoning | `agent.reasoning_effort` (medium) → low | fewer reasoning tokens on simple tasks |
| Toolset | `agent.disabled_toolsets` / `hermes tools` | smaller system prompt every turn |
| Memory trim | `memory.memory_char_limit` / `user_char_limit` | memory is injected EVERY turn; keep it lean |

Pitfalls:
- `hermes tools` requires an interactive TTY — it errors ("requires an interactive
  terminal") when piped or run non-interactively. Don't try to script it.
- Tool changes only take effect on `/reset` (new session) to preserve prompt caching.
- Config edits: use `hermes config set KEY VAL`, never hand-edit config.yaml.

## Reference

See `references/token-breakdown.md` for a worked example with real numbers and
the exact SQL used to diagnose a bogus cost estimate.
