#!/usr/bin/env python3
"""perf_bench.py — headless full-night timing (TICKET-02: every run <= 30 s).

Runs each Night 3 times (full duration, contract v1.2: 14400 / 16200 / 18000 ticks)
and reports min / median / max wall time. Exit 1 if any run exceeds 30 s.
Env: GODOT_BIN (default: `godot` on PATH). Output files go to out/.
"""
import os
import statistics
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT_BIN", "godot")
LIMIT_S = 30.0
NIGHTS = {1: 14400, 2: 16200, 3: 18000}


def run_once(night: int, ticks: int) -> float:
    out = os.path.join(ROOT, "out", f"perf_n{night}.jsonl")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    cmd = [GODOT, "--headless", "--path", ROOT, "--script", "res://src/headless.gd", "--",
           "--seed", "42", "--night", str(night), "--ticks", str(ticks), "--out", out]
    t0 = time.perf_counter()
    r = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    dt = time.perf_counter() - t0
    if r.returncode != 0:
        print(f"night {night}: godot exited {r.returncode}", file=sys.stderr)
        sys.exit(1)
    return dt


def main() -> int:
    bad = False
    for night, ticks in NIGHTS.items():
        times = [run_once(night, ticks) for _ in range(3)]
        print(f"night {night} ({ticks} ticks): min {min(times):.2f}s  median {statistics.median(times):.2f}s  max {max(times):.2f}s")
        if max(times) > LIMIT_S:
            bad = True
    print("PASS" if not bad else "FAIL (> 30 s)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
