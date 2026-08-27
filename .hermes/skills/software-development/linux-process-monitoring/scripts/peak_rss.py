#!/usr/bin/env python3
"""Peak RSS measurement via /proc polling. No GNU time required.

Usage:
  peak_rss.py -- <cmd> [args...]          # run command, report its peak RSS
  peak_rss.py --children -- <cmd> [...]   # include child processes (sum)
  peak_rss.py --pid <PID> [--seconds N]   # sample a running process tree

Output: PEAK_RSS_MB=<peak_mb> exit=<code>  (peak in MB, one decimal)

Why this exists: /usr/bin/time -v is missing on minimal Debian/containers,
and shell `cmd &` wrappers are rejected by the Hermes terminal tool
(foreground commands must not background). subprocess.Popen avoids both.
"""
import argparse
import os
import subprocess
import sys
import time


def _rss_kb(pid):
    try:
        with open(f"/proc/{pid}/status") as f:
            for line in f:
                if line.startswith("VmRSS:"):
                    return int(line.split()[1])  # kB
    except (FileNotFoundError, ProcessLookupError, PermissionError, ValueError):
        pass
    return 0


def _children(pid):
    out = set()
    try:
        for entry in os.listdir(f"/proc/{pid}/task"):
            try:
                with open(f"/proc/{pid}/task/{entry}/children") as f:
                    for tok in f.read().split():
                        if tok.isdigit():
                            out.add(int(tok))
                            out |= _children(int(tok))
            except (FileNotFoundError, ProcessLookupError):
                pass
    except (FileNotFoundError, ProcessLookupError):
        pass
    return out


def _tree_rss(pid):
    total = _rss_kb(pid)
    for c in _children(pid):
        total += _rss_kb(c)
    return total


def _sample_tree(pid, seconds):
    peak = 0
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        peak = max(peak, _tree_rss(pid))
        time.sleep(0.05)
    return peak


def _monitor_popen(proc, include_children):
    peak = 0
    while proc.poll() is None:
        try:
            rss = _tree_rss(proc.pid) if include_children else _rss_kb(proc.pid)
        except (ProcessLookupError, PermissionError):
            rss = 0
        peak = max(peak, rss)
        time.sleep(0.05)
    return peak


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--children", action="store_true")
    ap.add_argument("--pid", type=int, default=None)
    ap.add_argument("--seconds", type=float, default=10.0)
    args, rest = ap.parse_known_args()

    if args.pid is not None:
        peak = _sample_tree(args.pid, args.seconds)
        print(f"PEAK_RSS_MB={peak / 1024:.1f} (sampled PID {args.pid} {args.seconds}s)")
        return 0

    if not rest or rest[0] != "--":
        print("usage: peak_rss.py [--children] -- <cmd> [args...]", file=sys.stderr)
        return 2

    proc = subprocess.Popen(rest[1:], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    peak = _monitor_popen(proc, args.children)
    out, _ = proc.communicate()
    if out:
        print(out[-2000:])  # tail of captured stdout/stderr
    print(f"PEAK_RSS_MB={peak / 1024:.1f} exit={proc.returncode}")
    return proc.returncode or 0


if __name__ == "__main__":
    sys.exit(main())
