# Worked example: diagnosing a bogus cost estimate

Real session (Aug 2026). The user asked "evalúa cuántos tokens se han gastado
hasta la fecha con hermes", then "¿esos son millones o miles?".

## Numbers observed

- Period with data: ~6 weeks (Jul 1 – Aug 12, 2026)
- 131 sessions, 8,296 messages, 2,804 tool calls
- input_tokens      = 102,868,973
- output_tokens     =   1,032,922
- cache_read_tokens = 112,674,435
- reasoning_tokens  =      17,978
- estimated_cost_usd = $153,414.36  ← GARBAGE
- actual_cost_usd    = $0.00
- cost_status distribution: 151 NULL, 73 'estimated', 54 'unknown'

`hermes insights` reported "Total tokens: 216,551,747" = input + output +
cache_read (the report folds cache reads into its "total"). The honest headline
for the user is the input+output figure (~103.9M), plus a note that ~112M more
are cheap cache hits.

## Why the estimate was wrong

The dominant model was `gemini-3.5-flash-lite` (153M tokens) — a free-tier model
with no per-token price configured in Hermes' pricing table. The estimator fell
back to some default rate and produced a nonsense $153k figure. `actual_cost`
stayed $0 because no usage/billing API (e.g. OpenRouter with usage endpoint) is
wired up, so Hermes cannot see real spend.

Lesson: never quote `estimated_cost_usd` as real money. Lead with token counts;
for cost, say "actual is $0 (no billing API wired), and the estimator is not
trustworthy for free-tier models."

## Exact SQL used

```sql
-- aggregate
SELECT
  SUM(input_tokens)        AS input,
  SUM(output_tokens)       AS output,
  SUM(cache_read_tokens)   AS cache_read,
  SUM(cache_write_tokens)  AS cache_write,
  SUM(reasoning_tokens)    AS reasoning,
  SUM(estimated_cost_usd)  AS est_cost,
  SUM(actual_cost_usd)     AS actual_cost
FROM session_model_usage;

-- cost-status spread (tells you whether any model has real billing)
SELECT cost_status, COUNT(*) FROM session_model_usage GROUP BY cost_status;

-- per-model token ranking
SELECT model, SUM(input_tokens + output_tokens) AS tok
FROM session_model_usage
GROUP BY model ORDER BY tok DESC;
```

## Reading the user's "millones o miles" question

Spanish uses `.` as the thousands separator, so `102.868.973` reads as
"ciento dos millones ochocientos sesenta y ocho mil". When reporting, state the
unit in words ("102,8 millones") to avoid the ambiguity the user flagged.
