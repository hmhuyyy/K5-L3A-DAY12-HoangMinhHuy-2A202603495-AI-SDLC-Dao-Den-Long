# BenchStats.gd — frame statistics for the benchmark (TICKET-04 §3.1). Pure functions.
class_name BenchStats
extends RefCounted

static func _r1(x: float) -> float:
	return round(x * 10.0) / 10.0

# dts_ms: frame times in milliseconds (measurement window only).
#   N          = number of frames
#   avg_fps    = 1000 * N / sum(dt)
#   k          = max(1, ceil(0.01 * N));  p1_low_fps = 1000 / mean(k largest dt)
#   frame_ms_p95 = 95th percentile of dt (nearest-rank: sorted asc, index ceil(0.95*N)-1)
static func compute(dts_ms: Array) -> Dictionary:
	var n := dts_ms.size()
	if n == 0:
		return {"frames": 0, "avg_fps": 0.0, "p1_low_fps": 0.0, "frame_ms_p95": 0.0}
	var total := 0.0
	for d in dts_ms:
		total += float(d)
	var sorted := dts_ms.duplicate()
	sorted.sort()
	var k := maxi(1, int(ceil(0.01 * n)))
	var worst := 0.0
	for i in range(k):
		worst += float(sorted[n - 1 - i])
	worst /= float(k)
	var p95_idx := clampi(int(ceil(0.95 * n)) - 1, 0, n - 1)
	return {
		"frames": n,
		"avg_fps": _r1(1000.0 * n / total),
		"p1_low_fps": _r1(1000.0 / worst),
		"frame_ms_p95": _r1(float(sorted[p95_idx])),
	}
