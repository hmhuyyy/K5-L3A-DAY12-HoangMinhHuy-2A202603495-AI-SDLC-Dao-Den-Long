# SoakRunner.gd — 10-night soak harness (TICKET-04 §3.2). Headless, ONE process, no display dependency.
#
# Determinism contract (documented in docs/adr/ADR-004-bench-soak-leaderboard.md):
#   * Night i (i = 0..n-1) plays night number (i % 3) + 1 with seed 7 + i  (seed = --seed + i).
#   * The simulation uses its own SimRNG seeded with that seed.
#   * Inputs come from a SEPARATE RandomNumberGenerator (PCG32, `.seed = seed`) so input
#     generation never perturbs the simulation stream. Consumption order, per tick k:
#       if k % 30 == 0: 1 draw  -> angle = randf() * TAU  (move = (cos, sin), re-chosen every 30 ticks)
#       then exactly 4 draws    -> jump < 0.05, dash < 0.03, pulse < 0.02, interact < 0.10
#     Buttons are level-held for one tick (rising edges are detected by InputState).
#   * A Night runs until a terminal state (won / lost) or the standard duration + 2 ticks.
#   * "crash" = an invariant violation (NaN/Inf positions, negative counters) or a night that
#     fails to reach a terminal state within the duration. A real process crash produces no soak.json.
class_name SoakRunner
extends RefCounted

const ProcMem := preload("res://src/core/ProcMem.gd")

static func play_night(cfg: Config, night: int, seed_v: int, on_loaded: Callable = Callable()) -> Dictionary:
	var sim := GameSim.new()
	sim.init(cfg, seed_v, night, {})
	if on_loaded.is_valid():
		on_loaded.call()
	var irng := RandomNumberGenerator.new()
	irng.seed = seed_v
	var inp := InputState.new()
	var max_ticks := int(cfg.night_duration_s(night) * GameSim.TICK_RATE) + 2
	var dir := Vector2.ZERO
	var crashed := false
	var ticks := 0
	for k in range(max_ticks):
		inp.advance_prev()
		if k % 30 == 0:
			var a := irng.randf() * TAU
			dir = Vector2(cos(a), sin(a))
		inp.move = dir
		inp.jump = irng.randf() < 0.05
		inp.dash = irng.randf() < 0.03
		inp.pulse = irng.randf() < 0.02
		inp.interact = irng.randf() < 0.10
		sim.tick(inp)
		sim.bus.drain()
		ticks += 1
		if not _sane(sim):
			crashed = true
			break
		if sim.state == "won" or sim.state == "lost":
			break
	var result := sim.state
	if result != "won" and result != "lost":
		crashed = true   # never reached a terminal state within the standard duration
		result = "lost"
	return {"result": result, "crashed": crashed, "ticks": ticks, "score": sim.score}

static func _sane(sim: GameSim) -> bool:
	var p := sim.player.pos
	if is_nan(p.x) or is_nan(p.y) or is_nan(p.z) or is_inf(p.x) or is_inf(p.y) or is_inf(p.z):
		return false
	if sim.player.carried < 0 or sim.player.flames > 3:
		return false
	for sd: Entities.ShadeData in sim.shades:
		if is_nan(sd.pos.x) or is_nan(sd.pos.z):
			return false
	for ld: Entities.LanternData in sim.lanterns:
		if ld.fuel_units < 0 or ld.fuel_units > sim.cfg.fuel_max * 60:
			return false
	return true

static func _mb(v: float) -> Variant:
	return null if v < 0.0 else snappedf(v, 0.1)

# Returns the soak.json dictionary (also written to out_path when non-empty).
static func run(cfg: Config, base_seed: int, nights: int, out_path: String) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var results: Array = []
	var crashes := 0
	var holder := {}
	var mem_start: Variant = null
	var mem_end: Variant = null
	for i in range(nights):
		var cb := Callable()
		if i == 0:
			cb = func() -> void: holder["mem_start"] = _mb(ProcMem.rss_mb())
		var r := play_night(cfg, (i % 3) + 1, base_seed + i, cb)
		results.append(r["result"])
		if r["crashed"]:
			crashes += 1
	mem_start = holder.get("mem_start")   # RSS right after Night 1 finished loading
	mem_end = _mb(ProcMem.rss_mb())       # RSS after the last Night was played and its state released
	var out := {
		"nights": nights,
		"crashes": crashes,
		"results": results,
		"mem_start_mb": mem_start,
		"mem_end_mb": mem_end,
		"duration_s": snappedf((Time.get_ticks_msec() - t0) / 1000.0, 0.1),
	}
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(out, "  ") + "\n")
			f.close()
	return out
