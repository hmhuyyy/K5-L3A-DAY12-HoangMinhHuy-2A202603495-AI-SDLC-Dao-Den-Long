# GameSim.gd — Shared deterministic simulation.
# Used by both HeadlessRunner and 3D GameScene.
# Zero Node3D / Camera3D / Viewport / RenderingServer dependency.
class_name GameSim
extends RefCounted

const TICK_RATE := 60.0          # fixed ticks per second
const JUMP_DURATION_TICKS := 48  # 0.8 s * 60
const DEFAULT_SNAPSHOT_EVERY := 10

# ── dependencies (injected at init) ─────────────────────────
var cfg: Config
var rng: SimRNG
var bus: EventBus

# ── world state ──────────────────────────────────────────────
var player: Entities.PlayerData
var lanterns: Array[Entities.LanternData] = []
var motes: Array[Entities.MoteData] = []
var shades: Array[Entities.ShadeData] = []

# ── simulation state ─────────────────────────────────────────
var executed_ticks: int = 0
var initial_time_left_s: float = 0.0
var score: int = 0
var state: String = "playing"   # playing | won | lost
var night: int = 1

# Pulse cooldown (remaining ticks until usable again)
var pulse_cooldown_ticks: int = 0

# Scheduled shade spawning
var _next_shade_spawn_tick: int = 0  # tick at which next auto-spawn fires

# ── init ────────────────────────────────────────────────────
# cfg:  Config loaded from game.contract.json
# seed: --seed argument
# night_num: --night argument
# scenario: parsed scenario dict or empty {}
func init(p_cfg: Config, seed: int, night_num: int, scenario: Dictionary) -> void:
	cfg   = p_cfg
	night = night_num
	rng   = SimRNG.new()
	rng.seed_rng(seed)
	rng.reset_counters()
	bus   = EventBus.new()
	executed_ticks = 0
	score = 0
	state = "playing"
	pulse_cooldown_ticks = 0

	# Time — scenario override takes priority (Correction 3)
	if scenario.has("time_left_s"):
		initial_time_left_s = float(scenario["time_left_s"])
	else:
		initial_time_left_s = cfg.night1_duration_s

	_build_world(scenario)

	# Schedule first dynamic shade spawn (60 s after start)
	_next_shade_spawn_tick = int(60.0 * TICK_RATE)

# time_left_s computed on demand (Correction 3)
func time_left_s() -> float:
	return max(0.0, initial_time_left_s - executed_ticks / TICK_RATE)

# ── world construction ───────────────────────────────────────
func _build_world(scenario: Dictionary) -> void:
	_build_player(scenario)
	_build_lanterns(scenario)
	_build_motes(scenario)
	_build_shades(scenario)

func _build_player(s: Dictionary) -> void:
	player = Entities.PlayerData.new()
	if s.has("player"):
		var pd: Dictionary = s["player"]
		if pd.has("pos"):
			var p: Array = pd["pos"]
			player.pos = Vector3(float(p[0]), float(p[1]), float(p[2]))
		if pd.has("carried"):
			player.carried = int(pd["carried"])
		if pd.has("flames"):
			player.flames = int(pd["flames"])
		else:
			player.flames = cfg.flames
	else:
		player.flames = cfg.flames

func _build_lanterns(s: Dictionary) -> void:
	# Default positions: 5 lanterns evenly on a circle r=25 m
	lanterns = []
	var defaults: Array[Dictionary] = []
	for i in range(cfg.lantern_count_night1):
		var angle := TAU * i / cfg.lantern_count_night1
		defaults.append({
			"id": "L%d" % (i + 1),
			"pos": Vector3(25.0 * cos(angle), 0.0, 25.0 * sin(angle)),
			"deposited": 0,
			"lit": false
		})

	# Patch from scenario
	var patches: Dictionary = {}
	if s.has("lanterns"):
		for entry in s["lanterns"]:
			patches[entry["id"]] = entry

	for d in defaults:
		var ld := Entities.LanternData.new()
		ld.id = d["id"]
		ld.pos = d["pos"]
		ld.deposited = d["deposited"]
		ld.lit = d["lit"]
		if patches.has(ld.id):
			var p: Dictionary = patches[ld.id]
			if p.has("pos"):
				var pv: Array = p["pos"]
				ld.pos = Vector3(float(pv[0]), float(pv[1]), float(pv[2]))
			if p.has("deposited"):
				ld.deposited = int(p["deposited"])
			if p.has("lit"):
				ld.lit = bool(p["lit"])
		lanterns.append(ld)

func _build_motes(s: Dictionary) -> void:
	motes = []
	var random_motes := true
	if s.has("random_motes"):
		random_motes = bool(s["random_motes"])

	if s.has("motes"):
		# Scenario replaces the full list
		for entry in s["motes"]:
			var md := Entities.MoteData.new()
			md.id = rng.next_mote_id()
			var arr: Array = entry
			md.pos = Vector3(float(arr[0]), 0.0, float(arr[2]))
			md.active = true
			motes.append(md)
		return

	if not random_motes:
		return  # empty list, no auto-spawn

	# Default: 25 motes placed deterministically from seed on island
	for _i in range(25):
		var md := Entities.MoteData.new()
		md.id = rng.next_mote_id()
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(5.0, 35.0)
		md.pos = Vector3(radius * cos(angle), 0.0, radius * sin(angle))
		md.active = true
		motes.append(md)

func _build_shades(s: Dictionary) -> void:
	shades = []
	var random_shades := true
	if s.has("random_shades"):
		random_shades = bool(s["random_shades"])

	if s.has("shades"):
		for entry in s["shades"]:
			var sd := Entities.ShadeData.new()
			if entry.has("id"):
				sd.id = str(entry["id"])
			else:
				sd.id = rng.next_shade_id()
			var pos_arr: Array = entry["pos"]
			sd.pos = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
			shades.append(sd)
		return

	if not random_shades:
		return

	# Default: 2 initial shades at deterministic positions
	for i in range(2):
		var sd := Entities.ShadeData.new()
		sd.id = rng.next_shade_id()
		var angle := TAU * i / 2.0 + rng.randf_range(0.0, 0.5)
		sd.pos = Vector3(30.0 * cos(angle), 0.0, 30.0 * sin(angle))
		shades.append(sd)

# ── tick ─────────────────────────────────────────────────────
# Returns the EventBus (caller drains events after each tick).
# input_state: current InputState. May be null (player idle).
func tick(input_state: InputState) -> EventBus:
	if state != "playing":
		return bus

	var current_tick := executed_ticks + 1  # events this step tagged with k+1

	# NOTE: advance_prev() is called by the runner BEFORE apply_frame,
	# so edge detection sees the transition correctly. Do not call it here.

	# Step 2: player movement and jump
	_step_player_move(input_state, current_tick)

	# Step 3: collect eligible motes
	_step_collect_motes(current_tick)

	# Step 4: lantern interaction
	_step_lantern_interact(input_state, current_tick)

	# Step 5: pulse
	_step_pulse(input_state, current_tick)

	# Step 6: scheduled shade spawning
	_step_shade_spawn(current_tick)

	# Step 7: shade movement and stun
	_step_shades(current_tick)

	# Step 8: player hits
	_step_player_hits(current_tick)

	# Step 9: update time (computed on demand; tick counter advances below)

	# Step 10: terminal conditions
	executed_ticks += 1
	_step_pulse_cooldown()
	_check_terminal(current_tick)

	return bus

# ── movement ─────────────────────────────────────────────────
func _step_player_move(inp: InputState, _tick: int) -> void:
	if inp != null:
		var dir := inp.world_move()
		var speed_per_tick := cfg.player_speed / TICK_RATE
		player.pos.x += dir.x * speed_per_tick
		player.pos.z += dir.y * speed_per_tick

		# Jump (rising edge only, not while airborne)
		if inp.jump_edge() and not player.is_airborne():
			player.jump_tick = executed_ticks  # tick when jump started

	# Jump Y trajectory
	if player.is_airborne():
		var elapsed := executed_ticks - player.jump_tick
		if elapsed >= JUMP_DURATION_TICKS:
			player.pos.y = 0.0
			player.jump_tick = -1
		else:
			player.pos.y = Entities.PlayerData.jump_y(elapsed)

# ── mote collection ──────────────────────────────────────────
func _step_collect_motes(tick: int) -> void:
	if player.carried >= cfg.carry_capacity:
		return
	for md: Entities.MoteData in motes:
		if not md.active:
			continue
		if player.carried >= cfg.carry_capacity:
			break
		var dx: float = player.pos.x - md.pos.x
		var dz: float = player.pos.z - md.pos.z
		if sqrt(dx * dx + dz * dz) <= cfg.pickup_radius:
			md.active = false
			player.carried += 1
			score += cfg.score_per_mote
			bus.record(tick, "mote_picked", {"carried": player.carried})

# ── lantern interaction ───────────────────────────────────────
func _step_lantern_interact(inp: InputState, tick: int) -> void:
	if inp == null or not inp.interact_edge():
		return
	# Find nearest unlit lantern within interact_radius
	var best: Entities.LanternData = null
	var best_dist := INF
	for ld: Entities.LanternData in lanterns:
		if ld.lit:
			continue
		var dx: float = player.pos.x - ld.pos.x
		var dz: float = player.pos.z - ld.pos.z
		var d: float = sqrt(dx * dx + dz * dz)
		if d <= cfg.interact_radius and d < best_dist:
			best_dist = d
			best = ld
	if best == null or player.carried == 0:
		return
	var space := cfg.lantern_cost - best.deposited
	var amount := mini(player.carried, space)
	if amount <= 0:
		return
	player.carried -= amount
	best.deposited += amount
	bus.record(tick, "deposit", {
		"lantern_id": best.id,
		"amount": amount,
		"deposited": best.deposited
	})
	if best.deposited >= cfg.lantern_cost:
		best.lit = true
		bus.record(tick, "lantern_lit", {"lantern_id": best.id})
		score += cfg.score_per_lantern

# ── pulse ────────────────────────────────────────────────────
func _step_pulse(inp: InputState, tick: int) -> void:
	if inp == null or not inp.pulse_edge():
		return
	if pulse_cooldown_ticks > 0:
		return
	if player.carried < cfg.pulse_cost:
		return
	player.carried -= cfg.pulse_cost
	var stunned_ids: Array[String] = []
	for sd: Entities.ShadeData in shades:
		var dx: float = player.pos.x - sd.pos.x
		var dz: float = player.pos.z - sd.pos.z
		var d: float = sqrt(dx * dx + dz * dz)
		if d <= cfg.pulse_radius:
			sd.stun_ticks = int(cfg.pulse_stun_s * TICK_RATE)
			# Push shade away from player
			if d > 0.001:
				var nx: float = (sd.pos.x - player.pos.x) / d
				var nz: float = (sd.pos.z - player.pos.z) / d
				sd.pos.x += nx * cfg.pulse_push_m
				sd.pos.z += nz * cfg.pulse_push_m
			score += cfg.score_per_stun
			stunned_ids.append(sd.id)
	bus.record(tick, "pulse", {"stunned_ids": stunned_ids})
	pulse_cooldown_ticks = int(cfg.pulse_cooldown_s * TICK_RATE)

func _step_pulse_cooldown() -> void:
	if pulse_cooldown_ticks > 0:
		pulse_cooldown_ticks -= 1

# ── shade spawning ───────────────────────────────────────────
func _step_shade_spawn(tick: int) -> void:
	if executed_ticks < _next_shade_spawn_tick:
		return
	if shades.size() >= 5:
		return
	var sd := Entities.ShadeData.new()
	sd.id = rng.next_shade_id()
	var angle := rng.randf_range(0.0, TAU)
	sd.pos = Vector3(35.0 * cos(angle), 0.0, 35.0 * sin(angle))
	shades.append(sd)
	bus.record(tick, "shade_spawned", {"id": sd.id})
	_next_shade_spawn_tick += int(60.0 * TICK_RATE)

# ── shade movement ───────────────────────────────────────────
func _step_shades(_tick: int) -> void:
	for sd: Entities.ShadeData in shades:
		if sd.stun_ticks > 0:
			sd.stun_ticks -= 1
			continue
		# Chase player on XZ
		var dx: float = player.pos.x - sd.pos.x
		var dz: float = player.pos.z - sd.pos.z
		var dist: float = sqrt(dx * dx + dz * dz)
		if dist < 0.001:
			continue
		var step: float = cfg.shade_speed / TICK_RATE
		var nx: float = dx / dist
		var nz: float = dz / dist
		var nx_pos: float = sd.pos.x + nx * step
		var nz_pos: float = sd.pos.z + nz * step
		# Safe-radius check: cannot enter lit lantern's safe zone
		if _in_any_safe_zone(nx_pos, nz_pos):
			# Stay put — simple safe-zone enforcement
			pass
		else:
			sd.pos.x = nx_pos
			sd.pos.z = nz_pos

func _in_any_safe_zone(x: float, z: float) -> bool:
	for ld: Entities.LanternData in lanterns:
		if not ld.lit:
			continue
		var dx: float = x - ld.pos.x
		var dz: float = z - ld.pos.z
		if sqrt(dx * dx + dz * dz) <= cfg.safe_radius:
			return true
	return false

# ── player hits ──────────────────────────────────────────────
func _step_player_hits(tick: int) -> void:
	if player.invuln_ticks > 0:
		player.invuln_ticks -= 1
		return
	for sd: Entities.ShadeData in shades:
		if sd.stun_ticks > 0:
			continue
		var dx: float = player.pos.x - sd.pos.x
		var dz: float = player.pos.z - sd.pos.z
		if sqrt(dx * dx + dz * dz) <= cfg.shade_hit_radius:
			# Hit
			player.flames -= 1
			var dropped := floori(player.carried * cfg.hit_drop_ratio)
			player.carried -= dropped
			# Create dropped motes near player (Correction 1)
			_spawn_dropped_motes(dropped)
			bus.record(tick, "player_hit", {
				"by": "shade",
				"flames": player.flames,
				"dropped": dropped
			})
			player.invuln_ticks = int(cfg.invuln_s * TICK_RATE)
			break  # one hit per tick

func _spawn_dropped_motes(count: int) -> void:
	for _i in range(count):
		var md := Entities.MoteData.new()
		md.id = rng.next_mote_id()
		# Small deterministic scatter around player XZ
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(0.3, 1.0)
		md.pos = Vector3(
			player.pos.x + radius * cos(angle),
			0.0,
			player.pos.z + radius * sin(angle)
		)
		md.active = true
		motes.append(md)

# ── terminal conditions ───────────────────────────────────────
func _check_terminal(tick: int) -> void:
	# Priority: no_flames > all_lit > dawn (Correction 4)
	if player.flames <= 0:
		state = "lost"
		bus.record(tick, "game_over", {"result": "lost", "reason": "no_flames"})
		return
	var all_lit := true
	for ld: Entities.LanternData in lanterns:
		if not ld.lit:
			all_lit = false
			break
	if all_lit:
		# Win bonus
		score += int(cfg.score_per_second_left * floor(time_left_s()))
		score += cfg.score_per_flame_left * player.flames
		state = "won"
		bus.record(tick, "game_over", {"result": "won", "reason": "all_lit"})
		return
	if time_left_s() <= 0.0:
		state = "lost"
		bus.record(tick, "game_over", {"result": "lost", "reason": "dawn"})

# ── snapshot ─────────────────────────────────────────────────
# Returns the exact snapshot dict as defined in Test Contract v1.0.
func snapshot() -> Dictionary:
	var lantern_arr: Array = []
	for ld: Entities.LanternData in lanterns:
		lantern_arr.append({
			"id": ld.id,
			"pos": _vec3(ld.pos),
			"lit": ld.lit,
			"deposited": ld.deposited
		})
	var shade_arr: Array = []
	for sd: Entities.ShadeData in shades:
		shade_arr.append({
			"id": sd.id,
			"pos": _vec3(sd.pos),
			"state": sd.state_string()
		})
	var motes_active: int = 0
	var mote_arr: Array = []
	for md: Entities.MoteData in motes:
		if md.active:
			motes_active += 1
			mote_arr.append({"id": md.id, "pos": _vec3(md.pos)})

	var snap := {
		"type": "snapshot",
		"tick": executed_ticks,
		"sim_tick": executed_ticks,
		"state": state,
		"time_left_s": _r3(time_left_s()),
		"score": score,
		"player": {
			"pos": _vec3(player.pos),
			"flames": player.flames,
			"carried": player.carried
		},
		"lanterns": lantern_arr,
		"shades": shade_arr,
		"motes_active": motes_active,
		"motes": mote_arr  # recommended optional field
	}
	return snap

# Round Vector3 to 3 decimal places each axis.
func _vec3(v: Vector3) -> Array:
	return [_r3(v.x), _r3(v.y), _r3(v.z)]

# Round a float to 3 decimal places.
static func _r3(x: float) -> float:
	return round(x * 1000.0) / 1000.0

# Format a float for JSON output (used for time_left_s).
# Returns a float already rounded; JSON.stringify keeps it readable.
static func snapf(x: float, _places: int) -> float:
	return _r3(x)
