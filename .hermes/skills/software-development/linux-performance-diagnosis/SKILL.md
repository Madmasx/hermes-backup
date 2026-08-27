---
name: linux-performance-diagnosis
description: "Use when a Linux system feels slow. Find the real culprit."
version: 1.0.0
author: hermes
license: MIT
---

# Linux Performance Diagnosis ("the system feels slow")

## When to Use

User reports the machine/desktop feels slow, laggy, or stuttery, or asks for a performance
audit. Goal: find the REAL culprit with measured numbers, not guesses, then apply and
verify a fix.

## Triage order (fastest signal first)

1. `uptime` — load average vs cores (`nproc`). LOW load (e.g. 2 on 20 threads) with a
   laggy desktop = classic single-threaded-UI-process signature, NOT a saturated CPU.
2. `free -h` — read `available`, not `free`; check swap. Swap>0 or available≈0 = memory pressure.
3. `sensors` — thermal throttle? Package near `crit` (>90°C) = throttling, different fix.
4. `ps aux --sort=-%cpu | head` — top consumers. Look for the UI renderer
   (gnome-shell / kwin / compositor) and anything with a huge TIME column.
5. Confirm sustained load: `top -bn1 -p <PID>` several times, or CPU-ticks delta from
   `/proc/<PID>/stat` (fields 14+15 = utime+stime in jiffies). See scripts/pid_cpu_delta.sh.

## The "feels slow but load is low" signature

Load average normal + RAM fine + temps fine, but the desktop stutters ⇒ one or more
SINGLE-THREADED UI processes are pegging a core. The compositor (gnome-shell/kwin) is the
worst offender because it renders every interaction; each hot background process compounds
the input lag. This is why "the CPU isn't maxed but the desktop feels heavy" happens.

## Common culprits (check in this order)

- **gnome-shell at 80-110% CPU** ⇒ runaway GNOME extensions. Count them:
  `gsettings get org.gnome.shell enabled-extensions`. Look for REDUNDANT sets that fight
  each other (multiple dock extensions, multiple tiling managers) plus heavy effects
  (blur-my-shell, CoverflowAltTab 3D, animated docks). Fix = keep ONE of each class,
  disable the rest; disable blur for biggest win.
- **Launcher extensions (Ulauncher/Albert) with reindex loops**: read their engine code for
  `while True: build_index(); sleep(N)`. A full `os.walk` of $HOME every 2s is a common
  bug (near-real-time indexing done naively). Minimal reversible fix = raise sleep to 60s;
  heavier = disable the extension. See references/worked-example.md.
- **Live/animated wallpapers** (Hidamari, komorebi) burning 10-20% CPU 24/7 for cosmetics.
- **Browsers/Electron**: sum ALL child processes (`ps -C <browser> -o %cpu= | awk '{s+=$1}END{print s}'`),
  not just the main PID.

## Power governor / EPP (aggravating factor, rarely the root cause)

Check `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` and
`.../energy_performance_preference`. `powersave` + EPP `power` (or `energy_perf_bias=15`)
downclocks aggressively (cores idle at 400 MHz) and adds latency to bursty UI clicks.
`balance_performance` is snappier at some battery cost. Note: `powersave` governor is the
DEFAULT on Intel HWP and is fine — EPP is the real lever, not the governor name.

## Boot slowness (separate from runtime lag)

`systemd-analyze` and `systemd-analyze blame` — autostarted containers (lxc.service can
eat 30s+), `NetworkManager-wait-online`, plus `systemctl --failed` for broken units.

## Applying a fix to a running GUI/extension process

Python apps (Ulauncher extensions, etc.) load code at import time; editing the .py does
NOTHING until the process restarts. Restart cleanly via the app's systemd user unit:
`systemctl --user start <app>` works even when the unit is `disabled`. Verify with
`systemctl --user show <app> -p MainPID --value`, then list children with `ps --ppid <pid>`.

## Pitfalls

- **`pkill -f 'pattern'` kills your OWN shell** if the pattern string appears anywhere in
  your own command line (the tool wraps every command in `bash -c '...'`). This bit us:
  the shell died with exit -15 before the following `systemctl start` ran. Safe options:
  1. Kill by exact PID obtained from `pgrep` / `systemctl --user show ... -p MainPID`, then `kill <PID>`.
  2. Bracket trick `pkill -f '[u]launcher'` — but ONLY if the literal target name does NOT
     appear elsewhere in your command text (e.g. in `echo` strings, `pgrep -af 'ufinder/main.py'`
     still self-matched because the string "ufinder" was in the echo text). Prefer PID-based kill.
- **`ps %CPU` / `top -bn1` first iteration is a CUMULATIVE average since process start**, not
  instantaneous. To prove a process is idle: read `/proc/<PID>/stat` fields 14+15 (CPU ticks)
  twice ~5s apart — near-zero delta = idle; or `cat /proc/<PID>/wchan`
  (`do_epoll_wait` / `hrtimer_nanosleep` = sleeping).
- **A hot process doing a one-time initial index spikes right after restart.** Wait 30-90s
  and re-sample before concluding the fix failed.

## Verification (do both static + runtime after a code-level fix)

- Static: `compile()` the file + AST-inspect the changed call (assert new arg present, old
  arg absent). Temp script under /tmp prefixed `hermes-verify-`, remove when done.
- Runtime: process idle in `/proc/<PID>/wchan`, CPU-ticks delta ≈ 0 over a short window.

See references/worked-example.md for a full end-to-end case with concrete numbers.
