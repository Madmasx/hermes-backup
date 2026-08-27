#!/usr/bin/env bash
# Sample a PID's instantaneous CPU usage over a window (jiffies from /proc).
# Usage: pid_cpu_delta.sh <PID> [seconds]
# Near-zero delta = idle. state=S + wchan=do_epoll_wait/hrtimer_nanosleep = sleeping.
set -u
pid="${1:?usage: pid_cpu_delta.sh <PID> [seconds]}"
secs="${2:-6}"
[ -r "/proc/$pid/stat" ] || { echo "PID $pid not found"; exit 1; }

ticks() { awk '{print $14+$15}' "/proc/$pid/stat" 2>/dev/null || echo 0; }

t1=$(ticks); sleep "$secs"; t2=$(ticks)
delta=$((t2 - t1))
state=$(awk '{print $3}' "/proc/$pid/stat" 2>/dev/null)
wchan=$(cat "/proc/$pid/wchan" 2>/dev/null)
# 100 jiffies/sec typical (getconf CLK_TCK). Report ticks delta + approx avg %.
awk -v d="$delta" -v s="$secs" -v p="$pid" -v st="$state" -v w="$wchan" \
  'BEGIN { printf "PID=%s window=%ss cpu_ticks_delta=%d (~%.1f%% avg) state=%s wchan=%s\n", p, s, d, d/s, st, w }'
