---
name: linux-process-monitoring
description: "Measure process RAM/CPU on Linux: peak RSS, memory triage."
---

# Linux Process Monitoring & RAM Measurement

Measure, benchmark, and compare process memory/CPU on Linux. Answers like "does X use more RAM than Y?" with real measured numbers instead of theory.

## Quick triage — what is eating my RAM

```bash
ps aux --sort=-%mem | head -15    # top consumers (RSS column is real RAM)
free -h                           # watch 'available', not 'free'
pgrep -af -i 'name'               # find PIDs by pattern
grep VmRSS /proc/<PID>/status     # one process, exact RSS in kB
```

- RSS = resident = real RAM. VSZ = virtual address space, misleading for footprint questions — ignore it.
- Browsers/Electron/node spawn many child processes: sum the whole tree, not just the main PID.
- Node `--max-old-space-size=N` caps the V8 *heap*, not RSS: native buffers push RSS above the flag (observed: 8 GB heap flag → 11.4 GB RSS).
- A resident dev server holds RAM 24/7; a one-shot CLI peaks briefly and frees everything on exit. Compare the right shape (peak vs resident) before drawing conclusions.

## Peak RSS benchmark (reliable, no GNU time needed)

`/usr/bin/time -v` is often absent on minimal Debian/containers. Use the bundled script — pure /proc polling, works anywhere:

```bash
# run a command and report its peak RSS
python3 <this skill dir>/scripts/peak_rss.py -- <cmd> [args...]

# include child processes (node dev server + esbuild, browsers, multiprocessing)
python3 <this skill dir>/scripts/peak_rss.py --children -- <cmd> [args...]

# sample an already-running PID for N seconds
python3 <this skill dir>/scripts/peak_rss.py --pid <PID> --seconds 10
```

Output: `PEAK_RSS_MB=<peak> exit=<code>`.

## Hermes terminal pitfalls

- The terminal tool REJECTS foreground commands containing `&` (returns "use background=true"). Do NOT write `cmd &` shell wrappers to monitor a process. Two working patterns:
  1. `python3 - <<'EOF'` heredoc with `subprocess.Popen(cmd, stdout=subprocess.PIPE, ...)` and a VmRSS polling loop (what peak_rss.py does) — foreground-friendly, returns full output + peak.
  2. terminal(background=true, notify_on_complete=true) then process(action='wait') — but no live RSS; pattern 1 is better for benchmarks.
- Poll every 50–100 ms; slower polling misses short-lived peaks on fast CLIs.
- If the process exits before the first poll, peak reads 0 — the exit code still confirms the run happened.

## Worked example (Aug 2026)

One-shot Python CLI (graphify scan of a Go repo): peak ~59 MB. Next.js dev server on the same machine: ~11.4 GB resident. Measured with the script → ~200x difference; the CLI returned to 0 RSS after exit. Lesson: for "does X use more RAM than Y?", measure both shapes and report both.

## Verification

- Cross-check peak against `ps -o rss= -p <PID>` while the target runs (same source, /proc).
- Resident server: peak ≈ steady-state RSS. One-shot CLI: peak occurs mid-run, RSS returns to 0 after exit.
