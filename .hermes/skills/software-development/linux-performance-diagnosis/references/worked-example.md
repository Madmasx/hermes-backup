# Worked example — "se siente lenta a veces" (Aug 2026)

Acer Nitro laptop, i9-13900H (20 threads), 38 GB RAM, NVIDIA RTX 4060 hybrid, GNOME on Wayland.

## Symptoms
Desktop feels laggy/stuttery at times, not constant.

## Triage numbers (what ruled things out)
- `uptime`: load 1.93 on 20 threads → system NOT saturated.
- `free -h`: 31 GB available, swap 0 → no memory pressure.
- `sensors`: package 48°C, cores 41-45°C → no thermal throttling.
- `systemd-analyze`: boot 58s (lxc.service 30s, NetworkManager-wait-online 5.4s);
  lxc-net.service FAILED.

## Root causes found (real CPU consumers)
1. **gnome-shell 80-110% CPU sustained** (71 min CPU in 2.4h) — the UI compositor.
   Cause: 21 extensions enabled, including 4 dock extensions (dash-to-dock, dash-to-panel,
   dash2dock-lite, floatingDock) + 3 tiling managers (simple-tiling, tactile, tilingshell)
   + blur-my-shell + CoverflowAltTab, all running at once.
2. **ufinder Ulauncher extension 55-100% CPU** — bug confirmed by reading engine.py:
   `while True: build_index(); time.sleep(2)` did a full `os.walk` of $HOME (up to 100k
   files) + JSON dump every 2 seconds. One-line fix: `sleep(2)` → `sleep(60)`.
3. **Hidamari live wallpaper 10-20% CPU** (flatpak io.github.jeffshee.Hidamari).
4. Brave ~72% summed across all child processes (secondary).
5. Governor `powersave` + EPP `power` + `energy_perf_bias=15` → aggressive downclocking.

## Fix applied (safest, most reversible)
Patched `~/.local/share/ulauncher/extensions/com.github.elx4vier.ufinder/engine.py`
line 29: `time.sleep(2)` → `time.sleep(60)`. Restarted via `systemctl --user start ulauncher`
(unit was `disabled` but `start` still works for the current session).

## Verification
- Static: `compile()` + AST-asserted the only `time.sleep()` call now uses `60`, none use `2`.
- Runtime: new process idle — `wchan=do_epoll_wait`, `state=S`, CPU-ticks delta ≈ 0 between samples.
- CPU dropped from ~55-100% to ~3% average.

## Key lesson
"Feels slow but load is low" = single-threaded UI processes pegging cores, NOT overall
saturation. The compositor (gnome-shell) is the worst because it renders every interaction.
