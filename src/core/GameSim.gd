# GameSim.gd — Shared deterministic simulation (Phase 2, Contract v1.1).
# Used by both HeadlessRunner and 3D GameScene. No display dependency.
class_name GameSim
extends RefCounted

const TICK_RATE := 60.0
const DT := 1.0 / 60.0
const DEFAULT_SNAPSHOT_EVERY := 10

# Dash duration in ticks = 0.2s * 60 = 12
const DASH_TICKS := 12
# Wind cycle
const WIND_WARNING_TICKS := 120
const WIND_ACTIVE_TICKS := 300
const WIND_CYCLE_TICKS := 1800

var cfg: Config
var rng: SimRNG
var bus: EventBus
var world: Dictionary
var night: int = 1

var player: Entities.PlayerData
var lanterns: Array[Entities.LanternData] = []
var motes: Array[Entities.MoteData] = []
var shades: Array[Entities.ShadeData] = []
var drifters: Array[Entities.DrifterData] = []
var charms: Array[Entities.CharmData] = []

var executed_ticks: int = 0
var sim_tick: int = 0
var initial_time_left_s: float = 0.0
var score: int = 0
var state: String = "playing"   # playing | won | lost | paused
var paused: bool = false

# Wind (Night 3)
var wind_active: bool = false
var wind_dir_deg: float = 0.0
var _wind_next_warning_tick: int = 1680
var _wind_next_active_tick: int = 1800

# Spawn scheduling
var _next_mote_spawn_tick: int = 240
var _next_shade_spawn_tick: int = 0
var _shade_initial_spawned: bool = false
var _next_drifter_spawn_idx: int = 0
var _drifter_spawn_ticks: Array[int] = []

# Pulse push animation tracking: shade_id -> ticks_left
var _pulse_push_left: Dictionary = {}

func init(p_cfg: Config, seed: int, night_num: int, scenario: Dictionary) -> void:
	cfg = p_cfg
	night = night_num
	rng = SimRNG.new()
	rng.seed_rng(seed)
	rng.reset_counters()
	bus = EventBus.new()
	executed_ticks = 0
	sim_tick = 0
	score = 0
	state = "playing"
	paused = false
	wind_active = false
	wind_dir_deg = 0.0
	_pulse_push_left.clear()
	# world must be assigned BEFORE any _wind_enabled() / spawn-tick queries
	world = WorldDefs.for_night(night)
	# C5: first cycle — warning at tick 1680, active at tick 1800 (no wind in first 28 s)
	_wind_next_warning_tick = (WIND_CYCLE_TICKS - WIND_WARNING_TICKS) if _wind_enabled() else -1
	_wind_next_active_tick  = WIND_CYCLE_TICKS if _wind_enabled() else -1
	if scenario.has("time_left_s"):
		initial_time_left_s = float(scenario["time_left_s"])
	else:
		initial_time_left_s = cfg.night_duration_s(night)
	_build_world(scenario)
	_next_mote_spawn_tick = cfg.mote_spawn_interval_ticks
	_next_shade_spawn_tick = world.get("shade_spawn_first_tick", 300)
	_shade_initial_spawned = false
	# Drifter spawn ticks: copy into typed array (world returns untyped Array)
	var raw_drifter_ticks = world.get("drifter_spawn_ticks", [])
	_drifter_spawn_ticks.clear()
	for t in raw_drifter_ticks:
		_drifter_spawn_ticks.append(int(t))
	_next_drifter_spawn_idx = 0
	bus.record(0, "night_start", {"night": night})

func _wind_enabled() -> bool:
	return bool(world.get("wind_enabled", false))

# ── Benchmark workload (TICKET-04 §3.1) ───────────────────────
# Night 1, exactly 200 wander shades and 100 motes spread uniformly over the island
# (deterministic from the seed), L1–L3 lit with fuel 100, no player input, player at origin.
# Only used by the benchmark scene; never reachable from the headless pipeline.
var bench_mode: bool = false
const BENCH_SHADES := 200
const BENCH_MOTES := 100
const BENCH_ISLAND_R := 38.0

func init_bench(p_cfg: Config, seed_v: int) -> void:
	var sc := {
		"random_motes": false, "random_shades": false,
		"player": {"pos": [0.0, 0.0, 0.0]},
		"lanterns": [
			{"id": "L1", "lit": true, "fuel": 100},
			{"id": "L2", "lit": true, "fuel": 100},
			{"id": "L3", "lit": true, "fuel": 100},
		],
	}
	init(p_cfg, seed_v, 1, sc)
	bus.drain()
	while shades.size() < BENCH_SHADES:
		var p := _bench_point()
		if _in_any_safe_zone(p.x, p.z):
			continue
		var near_unlit := false
		for ld: Entities.LanternData in lanterns:
			if not ld.lit and _xz_dist(p, ld.pos) <= cfg.shade_drain_radius + 0.5:
				near_unlit = true
		if near_unlit:
			continue
		var sd := Entities.ShadeData.new()
		sd.id = rng.next_shade_id()
		sd.pos = p
		sd.state = Entities.SHADE_WANDER
		shades.append(sd)
	while motes.size() < BENCH_MOTES:
		var md := Entities.MoteData.new()
		md.id = rng.next_mote_id()
		md.pos = _bench_point()
		md.kind = Entities.MOTE_RANDOM
		motes.append(md)
	bench_mode = true

# Uniform over the disc of radius BENCH_ISLAND_R (area-uniform): r = R * sqrt(u).
func _bench_point() -> Vector3:
	var r := BENCH_ISLAND_R * sqrt(rng.randf())
	var a := rng.randf() * TAU
	return Vector3(r * cos(a), 0.0, r * sin(a))

# Moves all 200 benchmark shades in deterministic wander patrols across the island.
func _step_bench_shades() -> void:
	var speed := cfg.night_shade_speed(night)
	var step := speed * DT
	for i in range(shades.size()):
		var sd: Entities.ShadeData = shades[i]
		sd.state = Entities.SHADE_WANDER
		var heading := float(i) * 0.6180339887 * TAU + float(sim_tick) * 0.015
		var nx := sd.pos.x + cos(heading) * step
		var nz := sd.pos.z + sin(heading) * step
		if nx * nx + nz * nz > BENCH_ISLAND_R * BENCH_ISLAND_R or _in_any_safe_zone(nx, nz):
			heading += PI
			nx = sd.pos.x + cos(heading) * step
			nz = sd.pos.z + sin(heading) * step
		sd.pos.x = nx
		sd.pos.z = nz

# Lanterns that must be lit at dawn: ceil(win_ratio * total). The epsilon guards
# against float noise such as 0.6 * 5 = 3.0000000000000004.
func required_lit() -> int:
	return ceili(cfg.win_ratio * float(lanterns.size()) - 1e-9)

func time_left_s() -> float:
	return max(0.0, initial_time_left_s - sim_tick / TICK_RATE)

# ── World construction ────────────────────────────────────────
func _build_world(scenario: Dictionary) -> void:
	_build_player(scenario)
	_build_lanterns(scenario)
	_build_motes(scenario)
	_build_shades(scenario)
	_build_drifters(scenario)
	_build_charms(scenario)

func _build_player(s: Dictionary) -> void:
	player = Entities.PlayerData.new()
	player.capacity = cfg.carry_capacity
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
		if pd.has("invuln_ticks"):
			player.invuln_ticks = int(pd["invuln_ticks"])
		if pd.has("dash_cd_ticks"):
			player.dash_cd_ticks = int(pd["dash_cd_ticks"])
		if pd.has("pulse_cd_ticks"):
			player.pulse_cd_ticks = int(pd["pulse_cd_ticks"])
		if pd.has("charm_ticks"):
			player.charm_ticks = int(pd["charm_ticks"])
		if pd.has("successful_lights"):
			player.successful_lights = int(pd["successful_lights"])
			_update_capacity()
	else:
		player.flames = cfg.flames

func _build_lanterns(s: Dictionary) -> void:
	lanterns = []
	var defs: Array = world.get("lanterns", [])
	var patches: Dictionary = {}
	if s.has("lanterns"):
		for entry: Dictionary in s["lanterns"]:
			patches[str(entry["id"])] = entry
	for ld_def: Dictionary in defs:
		var ld := Entities.LanternData.new()
		ld.id = str(ld_def["id"])
		ld.pos = ld_def["pos"] as Vector3
		if patches.has(ld.id):
			var p: Dictionary = patches[ld.id]
			if p.has("pos"):
				var pv: Array = p["pos"]
				ld.pos = Vector3(float(pv[0]), float(pv[1]), float(pv[2]))
			if p.has("deposited"):
				ld.deposited = int(p["deposited"])
			if p.has("lit"):
				ld.lit = bool(p["lit"])
			if p.has("ever_lit"):
				ld.ever_lit = bool(p["ever_lit"])
			if p.has("relit_count"):
				ld.relit_count = int(p["relit_count"])
			# fuel: set from scenario or default for lit/unlit
			if p.has("fuel"):
				ld.fuel_units = roundi(float(p["fuel"]) * 60.0)
			elif ld.lit:
				ld.fuel_units = _full_fuel_units()  # full when pre-lit, no score
			# Ensure ever_lit is true if lit
			if ld.lit:
				ld.ever_lit = true
		lanterns.append(ld)

func _build_motes(s: Dictionary) -> void:
	motes = []
	var spawn_pts: Array = world.get("mote_spawn_points", [])
	var initial_idx: Array = world.get("mote_initial_indices", [])
	var random_motes := true
	if s.has("random_motes"):
		random_motes = bool(s["random_motes"])
	if s.has("motes"):
		for entry: Array in s["motes"]:
			var md := Entities.MoteData.new()
			md.id = rng.next_mote_id()
			md.pos = Vector3(float(entry[0]), 0.0, float(entry[2]))
			md.kind = "random"
			motes.append(md)
		return
	if not random_motes:
		return
	# Place initial_count motes at canonical spawn point positions
	var pts_to_use: Array = []
	if initial_idx.is_empty():
		# Fallback: first min(mote_initial_count, spawn_pts.size()) points
		for i in range(mini(cfg.mote_initial_count, spawn_pts.size())):
			pts_to_use.append(spawn_pts[i])
	else:
		for idx in initial_idx:
			if idx < spawn_pts.size():
				pts_to_use.append(spawn_pts[idx])
	for pt: Vector3 in pts_to_use:
		var md := Entities.MoteData.new()
		md.id = rng.next_mote_id()
		md.pos = pt
		md.kind = "random"
		motes.append(md)

func _build_shades(s: Dictionary) -> void:
	shades = []
	var random_shades := true
	if s.has("random_shades"):
		random_shades = bool(s["random_shades"])
	if s.has("shades"):
		for entry: Dictionary in s["shades"]:
			var sd := Entities.ShadeData.new()
			sd.id = entry.get("id", rng.next_shade_id()) as String
			var pv: Array = entry["pos"]
			sd.pos = Vector3(float(pv[0]), float(pv[1]), float(pv[2]))
			sd.state = entry.get("state", Entities.SHADE_CHASE)
			sd.state_ticks_left = int(entry.get("state_ticks_left", 0))
			sd.target_lantern_id = str(entry.get("target_lantern_id", ""))
			shades.append(sd)
		return
	if not random_shades:
		return
	# No initial shades from random; first 2 spawn at tick 300 via _step_shade_spawn

func _build_drifters(s: Dictionary) -> void:
	drifters = []
	if s.has("drifters"):
		for entry: Dictionary in s["drifters"]:
			var dr := Entities.DrifterData.new()
			dr.id = str(entry.get("id", rng.next_drifter_id()))
			var pv: Array = entry["pos"]
			dr.pos = Vector3(float(pv[0]), 0.0, float(pv[2]))
			dr.state = str(entry.get("state", Entities.DRIFTER_IDLE))
			dr.stolen = int(entry.get("stolen", 0))
			drifters.append(dr)

func _build_charms(s: Dictionary) -> void:
	charms = []
	var charm_defs: Array = world.get("charms", [])
	if s.has("charms"):
		for entry: Dictionary in s["charms"]:
			var c := Entities.CharmData.new()
			c.id = str(entry.get("id", ""))
			var pv: Array = entry["pos"]
			c.pos = Vector3(float(pv[0]), 0.0, float(pv[2]))
			c.available = bool(entry.get("available", true))
			c.respawn_ticks_left = int(entry.get("respawn_ticks_left", 0))
			charms.append(c)
		return
	for cd: Dictionary in charm_defs:
		var c := Entities.CharmData.new()
		c.id = str(cd["id"])
		c.pos = cd["pos"] as Vector3
		c.available = true
		charms.append(c)

# ── TICK (12-step order per TICKET-02) ───────────────────────
func tick(input_state: InputState) -> EventBus:
	var current_tick := executed_ticks + 1
	executed_ticks += 1
	if state == "won" or state == "lost":
		return bus

	# STEP 1: Read input; handle pause FIRST. If just paused, stop step here.
	if bench_mode:
		# Benchmark workload (TICKET-04 §3.1): all 200 shades stay in wander state and move
		# across the island; spawn, damage, pickup, fuel decay and terminal are disabled.
		_step_bench_shades()
		sim_tick += 1
		return bus
	if input_state != null and input_state.pause_edge():
		if paused:
			paused = false
			state = "playing" if state == "paused" else state
			bus.record(current_tick, "resumed", {})
			# Resume-tick runs full logic (D5 approved)
		else:
			paused = true
			state = "paused"
			bus.record(current_tick, "paused", {})
			return bus  # stop this step here
	if paused:
		return bus  # still paused: tick advances, nothing else runs

	# STEP 2: Decrement counters (time, cooldowns, invuln, stun, charm, TTL, respawn)
	_step_counters()

	# STEP 3: Move player (jump, dash, pad, wind) then check fall
	_step_player_move(input_state, current_tick)
	_step_fall(current_tick)

	# STEP 4: Pick up motes and charms
	_step_pickup(current_tick)

	# STEP 5: Lantern interaction
	_step_lantern_interact(input_state, current_tick)

	# STEP 6: Update safe zones (implicit in queries; nothing to do here)

	# STEP 7: Pulse
	_step_pulse(input_state, current_tick)

	# STEP 8: Move shades and drifters
	_step_shades(current_tick)
	_step_drifters(current_tick)

	# STEP 9: Contact — drifters steal first, then shades hit (by id asc)
	_step_drifter_steal(current_tick)
	_step_player_hits(current_tick)

	# STEP 10: Spawn motes/shades/drifters by schedule (new entities interact next tick)
	_step_spawns(current_tick)

	# STEP 11: Terminal conditions
	sim_tick += 1
	_check_terminal(current_tick)

	return bus

# ── STEP 2: counters ─────────────────────────────────────────
func _step_counters() -> void:
	if player.invuln_ticks > 0:
		player.invuln_ticks -= 1
	if player.dash_cd_ticks > 0:
		player.dash_cd_ticks -= 1
	if player.pulse_cd_ticks > 0:
		player.pulse_cd_ticks -= 1
	if player.charm_ticks > 0:
		player.charm_ticks -= 1
	for md: Entities.MoteData in motes:
		if md.active and md.ttl_ticks > 0:
			md.ttl_ticks -= 1
			if md.ttl_ticks <= 0:
				md.active = false
	for c: Entities.CharmData in charms:
		if not c.available and c.respawn_ticks_left > 0:
			c.respawn_ticks_left -= 1
			if c.respawn_ticks_left <= 0:
				c.available = true
	# Shade temporary-state timers (recoil / stunned) — step 2 per TICKET-02
	for sd: Entities.ShadeData in shades:
		if sd.state == Entities.SHADE_SPAWNING:
			continue
		if sd.state_ticks_left > 0:
			sd.state_ticks_left -= 1
			if sd.state_ticks_left <= 0:
				sd.state = Entities.SHADE_CHASE if sd.previous_state == Entities.SHADE_CHASE else Entities.SHADE_WANDER
				sd.previous_state = ""
	# Fuel (TICKET-03): integer units of 1/60 fuel. Lit lantern loses decay units per tick,
	# every draining shade adds drain units per tick.
	var decay_units := roundi(cfg.fuel_decay_per_s)
	var drain_units := roundi(cfg.drain_per_s)
	for ld: Entities.LanternData in lanterns:
		if not ld.lit:
			continue
		ld.fuel_units -= decay_units
		for sd: Entities.ShadeData in shades:
			if sd.state == Entities.SHADE_DRAIN and sd.target_lantern_id == ld.id:
				ld.fuel_units -= drain_units
	# fuel_drain events every 60 ticks per draining shade (fuel after this tick's update)
	var ev_tick := executed_ticks
	for sd: Entities.ShadeData in shades:
		if sd.state != Entities.SHADE_DRAIN:
			continue
		var dl := _find_lantern_by_id(sd.target_lantern_id)
		if dl == null or not dl.lit:
			continue
		sd.drain_ticks += 1
		if sd.drain_ticks >= 60:
			sd.drain_ticks = 0
			bus.record(ev_tick, "fuel_drain", {
				"lantern_id": dl.id, "shade_id": sd.id,
				"fuel": _r1(maxf(0.0, float(dl.fuel_units) / 60.0))
			})
	for ld: Entities.LanternData in lanterns:
		if ld.lit and ld.fuel_units <= 0:
			_extinguish(ld, ev_tick)

# ── STEP 3: player movement (jump, dash, bounce, wind, air control) ──
func _step_player_move(inp: InputState, tick: int) -> void:
	if player.falling:
		return
	# Jump (rising edge, grounded only)
	if inp != null and inp.jump_edge() and player.grounded:
		player.vel.y = cfg.jump_vel_y
		player.grounded = false
	# Dash (rising edge, cooldown ready)
	if inp != null and inp.dash_edge() and player.dash_cd_ticks <= 0 and player.dash_ticks_left <= 0:
		var dir: Vector2
		if inp.move.is_zero_approx():
			dir = player.facing
		else:
			dir = inp.world_move()
		player.dash_dir = dir
		player.dash_ticks_left = DASH_TICKS
		player.dash_cd_ticks = int(cfg.dash_cooldown_s * TICK_RATE)
		# Charm: no cooldown
		if player.charm_ticks > 0:
			player.dash_cd_ticks = 0
		bus.record(tick, "dash", {})
	# Bounce pad (swept contact)
	_step_bounce_pads()
	# Determine horizontal velocity source
	var hvel: Vector2
	if player.dash_ticks_left > 0:
		hvel = player.dash_dir * cfg.dash_speed
		player.dash_ticks_left -= 1
	elif player.ballistic:
		# Pad-imposed horizontal velocity (locked until grounded)
		hvel = player._ballistic_hvel
	else:
		# Ground/air control: same accel, max player_speed (C1 full air control)
		var charm_mult := cfg.charm_speed if player.charm_ticks > 0 else 1.0
		var max_speed := cfg.player_speed * (1.0 if player.charm_ticks <= 0 else charm_mult / cfg.player_speed)
		# Simplified: charm gives direct speed 7.2
		var target_speed := cfg.player_speed
		if player.charm_ticks > 0:
			target_speed = cfg.charm_speed
		var input_dir := Vector2.ZERO
		if inp != null:
			input_dir = inp.world_move()
		# Accelerate toward target velocity (≤0.1s = accel 60 m/s²)
		var accel := target_speed / cfg.player_accel_s
		var target := input_dir * target_speed
		var cur := Vector2(player.vel.x, player.vel.z)
		var diff := target - cur
		if diff.length() <= accel * DT:
			hvel = target
		else:
			hvel = cur + diff.normalized() * accel * DT
	# Apply gravity
	player.vel.y += cfg.gravity * DT
	# Integrate position
	player.vel.x = hvel.x
	player.vel.z = hvel.y
	player.pos += player.vel * DT
	# Update facing if moving
	if not inp.move.is_zero_approx():
		player.facing = inp.world_move().normalized()
	# Ground collision
	_step_ground_collide()
	# Wind (Night 3)
	_step_wind(tick)

func _step_ground_collide() -> void:
	var gh := WorldDefs.ground_height(world, night, player.pos.x, player.pos.z)
	if gh <= -100.0:
		player.grounded = false
		return
	if player.vel.y <= 0.0 and player.pos.y <= gh + 0.01:
		player.pos.y = gh
		player.vel.y = 0.0
		player.grounded = true
		player.ballistic = false
		player._ballistic_hvel = Vector2.ZERO
	else:
		player.grounded = false

func _step_bounce_pads() -> void:
	for pad: Dictionary in world.get("bounce_pads", []):
		var ppos: Vector3 = pad["pos"]
		var dx: float = player.pos.x - ppos.x
		var dz: float = player.pos.z - ppos.z
		if sqrt(dx * dx + dz * dz) <= 1.0 and player.vel.y <= 0.0:
			# Swept contact: foot crossed pad top this tick
			var prev_y := player.pos.y - player.vel.y * DT
			var pad_top := ppos.y
			if (prev_y >= pad_top - 0.5) and (player.pos.y <= pad_top + 0.5):
				player.vel.y = float(pad["vel_y"])
				var dir: Vector2 = pad["dir"]
				var hs: float = float(pad["h_speed"])
				player._ballistic_hvel = dir * hs
				player.ballistic = true
				player.grounded = false
				player.dash_ticks_left = 0
				return

func _step_wind(tick: int) -> void:
	if not _wind_enabled():
		return
	# Advance wind cycle
	if sim_tick == _wind_next_warning_tick and not wind_active:
		wind_dir_deg = rng.randf_range(0.0, 360.0)
	if sim_tick == _wind_next_active_tick:
		wind_active = true
	if wind_active:
		# Push player by wind_speed
		var a := deg_to_rad(wind_dir_deg)
		player.pos.x += cos(a) * cfg.wind_speed * DT
		player.pos.z += sin(a) * cfg.wind_speed * DT
		if sim_tick >= _wind_next_active_tick + WIND_ACTIVE_TICKS:
			wind_active = false
			_wind_next_warning_tick = sim_tick + (WIND_CYCLE_TICKS - WIND_ACTIVE_TICKS)
			_wind_next_active_tick = sim_tick + WIND_CYCLE_TICKS

# ── STEP 3b: fall check ──────────────────────────────────────
func _step_fall(tick: int) -> void:
	if player.falling:
		player.fall_wait_ticks -= 1
		if player.fall_wait_ticks <= 0:
			# Respawn
			player.pos = WorldDefs.player_spawn(night)
			player.vel = Vector3.ZERO
			player.invuln_ticks = cfg.invuln_ticks
			player.falling = false
			player.grounded = true
			if player.flames <= 0:
				_check_terminal(tick)
		return
	if not cfg.fall_enabled:
		return
	if player.pos.y < cfg.fall_y_threshold and not player.falling:
		# Fall once, bypass invuln
		player.falling = true
		player.fall_wait_ticks = cfg.fall_wait_ticks
		player.flames -= 1
		# Lose all carried motes (dropped at fall point — but fall point is off-island,
		# so they become uncollectable; record lost)
		var lost := player.carried
		player.carried = 0
		bus.record(tick, "player_hit", {
			"by": "fall",
			"flames": player.flames,
			"dropped": 0,
			"lost": lost
		})
		if player.flames <= 0:
			_check_terminal(tick)

# ── STEP 4: pickup motes and charms ──────────────────────────
func _step_pickup(tick: int) -> void:
	if player.falling:
		return
	# Motes
	for md: Entities.MoteData in motes:
		if not md.active:
			continue
		if player.carried >= player.capacity:
			break
		var dx: float = player.pos.x - md.pos.x
		var dz: float = player.pos.z - md.pos.z
		if sqrt(dx * dx + dz * dz) <= cfg.pickup_radius:
			# Height check: mote is at ground; player foot height diff <= 1.5
			var mote_ground := md.pos.y
			if absf(player.pos.y - mote_ground) <= cfg.pickup_height_m:
				md.active = false
				player.carried += 1
				bus.record(tick, "mote_picked", {"carried": player.carried})
	# Charms
	for c: Entities.CharmData in charms:
		if not c.available:
			continue
		var dx: float = player.pos.x - c.pos.x
		var dz: float = player.pos.z - c.pos.z
		if sqrt(dx * dx + dz * dz) <= cfg.pickup_radius:
			c.available = false
			c.respawn_ticks_left = cfg.charm_respawn_ticks
			player.charm_ticks = cfg.charm_duration_ticks
			bus.record(tick, "charm_picked", {
				"charm_id": c.id,
				"charm_ticks": cfg.charm_duration_ticks
			})

# ── STEP 5: lantern interaction ─────────────────────────────
# TICKET-03: candidates = unlit (first light / relight) or lit with fuel < full.
# Nearest within interact_radius, tie-break id ascending. Full lanterns are never selected.
func _step_lantern_interact(inp: InputState, tick: int) -> void:
	if inp == null or not inp.interact_edge():
		return
	if player.falling:
		return
	var best: Entities.LanternData = null
	var best_dist := INF
	for ld: Entities.LanternData in lanterns:
		if ld.lit and ld.fuel_units >= _full_fuel_units():
			continue
		var d := _xz_dist(player.pos, ld.pos)
		if d <= cfg.interact_radius:
			if d < best_dist or (d == best_dist and ld.id < best.id):
				best_dist = d
				best = ld
	if best == null or player.carried <= 0:
		return
	if not best.lit:
		var relight := best.ever_lit
		var cost := cfg.relight_cost if relight else cfg.lantern_cost
		var amount := mini(player.carried, cost - best.deposited)
		if amount <= 0:
			return
		player.carried -= amount
		best.deposited += amount
		score += amount * cfg.score_per_mote
		bus.record(tick, "deposit", {
			"lantern_id": best.id, "amount": amount, "deposited": best.deposited
		})
		if best.deposited >= cost:
			best.lit = true
			best.fuel_units = _full_fuel_units()
			best.ever_lit = true
			best.deposited = 0  # deposited counts motes toward the CURRENT light-up only
			if relight:
				best.relit_count += 1
				score += cfg.score_per_relight
			else:
				score += cfg.score_per_lantern
			player.successful_lights += 1
			_update_capacity()
			bus.record(tick, "lantern_lit", {"lantern_id": best.id, "relight": relight})
			_trigger_safe_push(best)
	else:
		# Refuel: used = min(carried, ceil((fuel_max - fuel) / fuel_per_mote)) — integer arithmetic
		var per_mote_units := cfg.fuel_per_mote * 60
		var missing := _full_fuel_units() - best.fuel_units
		var used := mini(player.carried, (missing + per_mote_units - 1) / per_mote_units)
		if used <= 0:
			return
		var was_weak := best.fuel_units < _low_fuel_units()
		player.carried -= used
		best.fuel_units = mini(_full_fuel_units(), best.fuel_units + used * per_mote_units)
		score += used * cfg.score_per_mote
		bus.record(tick, "refuel", {
			"lantern_id": best.id, "amount": used, "fuel": _r1(float(best.fuel_units) / 60.0)
		})
		if was_weak and best.fuel_units >= _low_fuel_units():
			_trigger_safe_push(best)

func _update_capacity() -> void:
	player.capacity = mini(cfg.capacity_max, 10 + 2 * player.successful_lights)

static func _r1(x: float) -> float:
	return round(x * 10.0) / 10.0

# ── STEP 7: pulse ────────────────────────────────────────────
func _step_pulse(inp: InputState, tick: int) -> void:
	if inp == null or not inp.pulse_edge():
		return
	if player.pulse_cd_ticks > 0:
		return
	if player.carried < cfg.pulse_cost:
		return
	player.carried -= cfg.pulse_cost
	player.pulse_cd_ticks = int(cfg.pulse_cooldown_s * TICK_RATE)
	var stunned_ids: Array[String] = []
	# Center = player foot + 0.8 Y; 3D distance to shade center
	var center := Vector3(player.pos.x, player.pos.y + cfg.pulse_center_height_m, player.pos.z)
	for sd: Entities.ShadeData in shades:
		var dx: float = center.x - sd.pos.x
		var dy: float = center.y - sd.pos.y
		var dz: float = center.z - sd.pos.z
		var d: float = sqrt(dx * dx + dy * dy + dz * dz)
		if d <= cfg.pulse_radius:
			# Stun: stunned overrides recoil/drain. Remember the pre-pulse state for hysteresis.
			var was_drain := sd.state == Entities.SHADE_DRAIN
			if sd.state == Entities.SHADE_WANDER or sd.state == Entities.SHADE_CHASE:
				sd.previous_state = sd.state
			elif sd.state == Entities.SHADE_DRAIN or sd.state == Entities.SHADE_SPAWNING:
				sd.previous_state = Entities.SHADE_WANDER
			# recoil / stunned: keep the previously saved state
			sd.state = Entities.SHADE_STUNNED
			sd.state_ticks_left = cfg.pulse_stun_ticks
			sd.drain_ticks = 0
			_pulse_push_left[sd.id] = cfg.pulse_push_ticks
			# Score: +15 total if it was draining right before the pulse, else +5
			if was_drain:
				score += cfg.score_per_stun_drain
			else:
				score += cfg.score_per_stun
			stunned_ids.append(sd.id)
			# Drifter hit by pulse
	for dr: Entities.DrifterData in drifters:
		if dr.state == Entities.DRIFTER_REMOVED:
			continue
		var dx: float = center.x - dr.pos.x
		var dy: float = center.y - dr.pos.y
		var dz: float = center.z - dr.pos.z
		var d: float = sqrt(dx * dx + dy * dy + dz * dz)
		if d <= cfg.pulse_radius:
			if dr.state == Entities.DRIFTER_CHASE:
				dr.state = Entities.DRIFTER_FLEE
				dr.state_ticks_left = cfg.drifter_flee_ticks
			elif dr.state == Entities.DRIFTER_FLEE and dr.stolen > 0:
				# Drop stolen motes at spot
				_spawn_dropped_motes_at(dr.pos, dr.stolen)
				bus.record(tick, "drifter_drop", {"drifter_id": dr.id, "amount": dr.stolen})
				dr.stolen = 0
				dr.state_ticks_left = 120
	bus.record(tick, "pulse", {"stunned_ids": stunned_ids})

# ── STEP 8a: shade movement & state machine ───────────────────
func _step_shades(tick: int) -> void:
	# Pulse push animation (4 m over 15 ticks, away from player; +X when coincident)
	for shade_id: String in _pulse_push_left.keys():
		var left: int = _pulse_push_left[shade_id]
		if left > 0:
			var psd := _find_shade(shade_id)
			if psd != null and psd.state == Entities.SHADE_STUNNED and psd.push_ticks_left <= 0:
				var pdx: float = psd.pos.x - player.pos.x
				var pdz: float = psd.pos.z - player.pos.z
				var pd := sqrt(pdx * pdx + pdz * pdz)
				var push := cfg.pulse_push_m / float(cfg.pulse_push_ticks)
				if pd > 0.001:
					psd.pos.x += (pdx / pd) * push
					psd.pos.z += (pdz / pd) * push
				else:
					psd.pos.x += push
			_pulse_push_left[shade_id] = left - 1
		else:
			_pulse_push_left.erase(shade_id)

	for sd: Entities.ShadeData in shades:
		_step_shade_one(sd, tick)

func _step_shade_one(sd: Entities.ShadeData, _tick: int) -> void:
	# spawning -> wander after first tick (no movement on that tick)
	if sd.state == Entities.SHADE_SPAWNING:
		sd.state = Entities.SHADE_WANDER
		return
	# Safe-zone push-out overrides AI movement (and suppresses damage, see hits)
	if sd.push_ticks_left > 0:
		_apply_safe_push(sd)
		return
	match sd.state:
		Entities.SHADE_STUNNED:
			return
		Entities.SHADE_RECOIL:
			var rdx: float = sd.pos.x - player.pos.x
			var rdz: float = sd.pos.z - player.pos.z
			var rd := sqrt(rdx * rdx + rdz * rdz)
			var rstep := cfg.shade_recoil_m / float(cfg.shade_recoil_ticks)
			if rd > 0.001:
				sd.pos.x += (rdx / rd) * rstep
				sd.pos.z += (rdz / rd) * rstep
			else:
				sd.pos.x += rstep
			return
		Entities.SHADE_DRAIN:
			_step_shade_drain(sd)
			return
	# wander <-> chase hysteresis (player distance, XZ)
	var dist := _xz_dist(player.pos, sd.pos)
	if sd.state == Entities.SHADE_WANDER and dist <= cfg.shade_detect_m:
		sd.state = Entities.SHADE_CHASE
	elif sd.state == Entities.SHADE_CHASE and dist > cfg.shade_abandon_m:
		sd.state = Entities.SHADE_WANDER
	if sd.state == Entities.SHADE_CHASE:
		# chase never retargets lanterns (TICKET-03 §4); target id is left untouched
		_shade_move_toward(sd, player.pos.x, player.pos.z)
	else:
		_step_shade_wander(sd)

# Wander: nearest weak lit lantern (fuel < threshold), else nearest unlit lantern.
func _step_shade_wander(sd: Entities.ShadeData) -> void:
	var tgt := _pick_wander_target(sd)
	if tgt == null:
		sd.target_lantern_id = ""
		return
	sd.target_lantern_id = tgt.id
	var d := _xz_dist(tgt.pos, sd.pos)
	if d <= cfg.shade_drain_radius:
		if tgt.lit:
			sd.state = Entities.SHADE_DRAIN
			sd.drain_ticks = 0
		return  # arrived at an unlit lantern: stand still (nothing to drain)
	_shade_move_toward(sd, tgt.pos.x, tgt.pos.z)

func _step_shade_drain(sd: Entities.ShadeData) -> void:
	var tgt := _find_lantern_by_id(sd.target_lantern_id)
	# 1. player within 6 m (= safe_radius) -> chase
	if _xz_dist(player.pos, sd.pos) <= cfg.safe_radius:
		_leave_drain(sd, Entities.SHADE_CHASE)
		return
	# 2. lantern gone/out -> wander
	if tgt == null or not tgt.lit:
		_leave_drain(sd, Entities.SHADE_WANDER)
		return
	# 3. refuelled to >= threshold -> wander
	if tgt.fuel_units >= _low_fuel_units():
		_leave_drain(sd, Entities.SHADE_WANDER)
		return
	# 4. farther than drain radius -> wander
	if _xz_dist(tgt.pos, sd.pos) > cfg.shade_drain_radius:
		_leave_drain(sd, Entities.SHADE_WANDER)

func _leave_drain(sd: Entities.ShadeData, new_state: String) -> void:
	sd.state = new_state
	sd.drain_ticks = 0
	if new_state == Entities.SHADE_WANDER:
		sd.target_lantern_id = ""

func _shade_move_toward(sd: Entities.ShadeData, tx: float, tz: float) -> void:
	var dx: float = tx - sd.pos.x
	var dz: float = tz - sd.pos.z
	var d := sqrt(dx * dx + dz * dz)
	if d <= 0.001:
		return
	var step := cfg.night_shade_speed(night) * DT
	var nx: float = sd.pos.x + dx / d * step
	var nz: float = sd.pos.z + dz / d * step
	if not _in_any_safe_zone(nx, nz):
		sd.pos.x = nx
		sd.pos.z = nz

func _apply_safe_push(sd: Entities.ShadeData) -> void:
	var left := sd.push_ticks_left
	sd.pos.x += (sd.push_to.x - sd.pos.x) / float(left)
	sd.pos.z += (sd.push_to.y - sd.pos.z) / float(left)
	sd.push_ticks_left = left - 1

# A lantern just became a safe zone (lit / relit / refuelled to >= threshold):
# shades inside are pushed to the rim within safe_push_ticks and cannot hurt meanwhile.
func _trigger_safe_push(ld: Entities.LanternData) -> void:
	for sd: Entities.ShadeData in shades:
		var dx: float = sd.pos.x - ld.pos.x
		var dz: float = sd.pos.z - ld.pos.z
		var d := sqrt(dx * dx + dz * dz)
		if d >= cfg.safe_radius:
			continue
		var ux := 1.0
		var uz := 0.0
		if d > 0.001:
			ux = dx / d
			uz = dz / d
		var rim := cfg.safe_radius + 0.01
		sd.push_to = Vector2(ld.pos.x + ux * rim, ld.pos.z + uz * rim)
		sd.push_ticks_left = cfg.safe_push_ticks
		if sd.target_lantern_id == ld.id:
			sd.target_lantern_id = ""

func _pick_wander_target(sd: Entities.ShadeData) -> Entities.LanternData:
	var weak := _nearest_lantern_to(sd.pos, true)
	var cur := _find_lantern_by_id(sd.target_lantern_id)
	# Keep a still-valid explicit/current target; weak lit lanterns always win over unlit ones.
	if cur != null:
		if cur.lit and cur.fuel_units < _low_fuel_units():
			return cur
		if not cur.lit and weak == null:
			return cur
	if weak != null:
		return weak
	return _nearest_lantern_to(sd.pos, false)

# weak_lit=true: lit lanterns with fuel < threshold; false: unlit lanterns. Nearest, tie id asc.
func _nearest_lantern_to(p: Vector3, weak_lit: bool) -> Entities.LanternData:
	var best: Entities.LanternData = null
	var best_d := INF
	for ld: Entities.LanternData in lanterns:
		if weak_lit:
			if not ld.lit or ld.fuel_units >= _low_fuel_units():
				continue
		elif ld.lit:
			continue
		var d := _xz_dist(ld.pos, p)
		if d < best_d or (d == best_d and best != null and ld.id < best.id):
			best_d = d
			best = ld
	return best

func _low_fuel_units() -> int:
	return cfg.low_fuel_threshold * 60

func _full_fuel_units() -> int:
	return cfg.fuel_max * 60

static func _xz_dist(a: Vector3, b: Vector3) -> float:
	var dx := a.x - b.x
	var dz := a.z - b.z
	return sqrt(dx * dx + dz * dz)

func _find_shade(id: String) -> Entities.ShadeData:
	for sd: Entities.ShadeData in shades:
		if sd.id == id:
			return sd
	return null

func _find_lantern_by_id(id: String) -> Entities.LanternData:
	for ld: Entities.LanternData in lanterns:
		if ld.id == id:
			return ld
	return null

# A lantern ran dry: dark, deposited reset, ever_lit/relit_count kept, drainers go wander.
func _extinguish(ld: Entities.LanternData, tick: int) -> void:
	ld.fuel_units = 0
	ld.lit = false
	ld.deposited = 0
	ld.ever_lit = true
	for sd: Entities.ShadeData in shades:
		if sd.state == Entities.SHADE_DRAIN and sd.target_lantern_id == ld.id:
			_leave_drain(sd, Entities.SHADE_WANDER)
	bus.record(tick, "lantern_out", {"lantern_id": ld.id})

func _in_any_safe_zone(x: float, z: float) -> bool:
	for ld: Entities.LanternData in lanterns:
		if not ld.lit:
			continue
		# TICKET-03 §4: fuel < low_fuel_threshold removes safe zone
		var fuel_actual := float(ld.fuel_units) / 60.0
		if fuel_actual < float(cfg.low_fuel_threshold):
			continue
		var dx: float = x - ld.pos.x
		var dz: float = z - ld.pos.z
		if sqrt(dx * dx + dz * dz) <= cfg.safe_radius:
			return true
	return false

# ── STEP 8b: drifter movement ─────────────────────────────────
func _step_drifters(_tick: int) -> void:
	for dr: Entities.DrifterData in drifters:
		match dr.state:
			Entities.DRIFTER_IDLE:
				# Circle R≈3.82m, 0.5°/tick (B14)
				dr.heading_deg += 0.5
				if dr.heading_deg >= 360.0:
					dr.heading_deg -= 360.0
				var a := deg_to_rad(dr.heading_deg)
				dr.pos.x += cos(a) * cfg.drifter_speed_idle * DT
				dr.pos.z += sin(a) * cfg.drifter_speed_idle * DT
				# Transition: carried >=5 and within 15m
				var dx: float = player.pos.x - dr.pos.x
				var dz: float = player.pos.z - dr.pos.z
				if player.carried >= cfg.drifter_carried_min and sqrt(dx*dx+dz*dz) <= cfg.drifter_detect_m:
					dr.state = Entities.DRIFTER_CHASE
			Entities.DRIFTER_CHASE:
				var dx: float = player.pos.x - dr.pos.x
				var dz: float = player.pos.z - dr.pos.z
				var dist := sqrt(dx*dx+dz*dz)
				# Revert to idle if condition lost
				if player.carried < cfg.drifter_carried_min or dist > cfg.drifter_detect_m:
					dr.state = Entities.DRIFTER_IDLE
				elif dist > 0.001:
					dr.pos.x += (dx/dist) * cfg.drifter_speed_chase * DT
					dr.pos.z += (dz/dist) * cfg.drifter_speed_chase * DT
			Entities.DRIFTER_FLEE:
				if dr.state_ticks_left > 0:
					dr.state_ticks_left -= 1
					var dx: float = player.pos.x - dr.pos.x
					var dz: float = player.pos.z - dr.pos.z
					var dist := sqrt(dx*dx+dz*dz)
					if dist > 0.001:
						dr.pos.x -= (dx/dist) * cfg.drifter_speed_flee * DT
						dr.pos.z -= (dz/dist) * cfg.drifter_speed_flee * DT
				else:
					dr.state = Entities.DRIFTER_REMOVED

# ── STEP 9a: drifter steal ───────────────────────────────────
func _step_drifter_steal(tick: int) -> void:
	for dr: Entities.DrifterData in drifters:
		if dr.state != Entities.DRIFTER_CHASE or dr.has_stolen:
			continue
		if player.falling:
			continue
		var dx: float = player.pos.x - dr.pos.x
		var dz: float = player.pos.z - dr.pos.z
		if sqrt(dx*dx+dz*dz) <= cfg.drifter_steal_radius:
			var stolen := mini(cfg.drifter_steal_max_motes, player.carried)
			player.carried -= stolen
			dr.stolen = stolen
			dr.has_stolen = true
			dr.state = Entities.DRIFTER_FLEE
			dr.state_ticks_left = cfg.drifter_flee_ticks
			bus.record(tick, "drifter_steal", {
				"drifter_id": dr.id,
				"amount": stolen,
				"carried": player.carried
			})

# ── STEP 9b: shade hits player ───────────────────────────────
func _step_player_hits(tick: int) -> void:
	if player.invuln_ticks > 0 or player.falling:
		return
	# Sort shades by id ascending (string sort ≈ numeric for S1,S2...)
	var sorted_shades := shades.duplicate()
	sorted_shades.sort_custom(func(a: Entities.ShadeData, b: Entities.ShadeData): return a.id < b.id)
	for sd: Entities.ShadeData in sorted_shades:
		if sd.state == Entities.SHADE_STUNNED or sd.push_ticks_left > 0:
			continue
		# XZ distance + height check
		var dx: float = player.pos.x - sd.pos.x
		var dz: float = player.pos.z - sd.pos.z
		if sqrt(dx*dx+dz*dz) > cfg.shade_hit_radius:
			continue
		if absf(player.pos.y - sd.pos.y) > cfg.shade_hit_height_m:
			continue
		# Hit
		player.flames -= 1
		var dropped := floori(float(player.carried) / 2.0)
		player.carried -= dropped
		player.invuln_ticks = cfg.invuln_ticks
		# Dropped motes in ring
		_spawn_dropped_motes_ring(dropped)
		bus.record(tick, "player_hit", {
			"by": "shade",
			"flames": player.flames,
			"dropped": dropped
		})
		# Shade enters recoil
		sd.previous_state = Entities.SHADE_CHASE
		sd.state = Entities.SHADE_RECOIL
		sd.state_ticks_left = cfg.shade_recoil_ticks
		break  # max 1 flame lost per tick

func _spawn_dropped_motes_ring(count: int) -> void:
	for _i in range(count):
		var md := Entities.MoteData.new()
		md.id = rng.next_mote_id()
		var angle := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(cfg.mote_drop_ring_min_m, cfg.mote_drop_ring_max_m)
		md.pos = Vector3(player.pos.x + r * cos(angle), 0.0, player.pos.z + r * sin(angle))
		md.kind = "dropped"
		md.ttl_ticks = cfg.mote_drop_ttl_ticks
		md.active = false  # collectible from next tick
		motes.append(md)
	# Activate deferred motes at end of tick by marking them active
	for md: Entities.MoteData in motes:
		if md.kind == "dropped" and md.ttl_ticks == cfg.mote_drop_ttl_ticks and not md.active:
			md.active = true

func _spawn_dropped_motes_at(pos: Vector3, count: int) -> void:
	for _i in range(count):
		var md := Entities.MoteData.new()
		md.id = rng.next_mote_id()
		var angle := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(0.5, 1.5)
		md.pos = Vector3(pos.x + r * cos(angle), 0.0, pos.z + r * sin(angle))
		md.kind = "dropped"
		md.ttl_ticks = cfg.mote_drop_ttl_ticks
		md.active = true
		motes.append(md)

# ── STEP 10: spawns ───────────────────────────────────────────
func _step_spawns(tick: int) -> void:
	_step_spawn_motes(tick)
	_step_spawn_shades(tick)
	_step_spawn_drifters(tick)

func _step_spawn_motes(tick: int) -> void:
	if sim_tick < _next_mote_spawn_tick:
		return
	_next_mote_spawn_tick += cfg.mote_spawn_interval_ticks
	var active_count := 0
	for md: Entities.MoteData in motes:
		if md.active:
			active_count += 1
	if active_count >= cfg.mote_cap:
		return
	var spawn_pts: Array = world.get("mote_spawn_points", [])
	var occupied: Dictionary = {}
	for md: Entities.MoteData in motes:
		if md.active and md.kind == "random":
			var key := "%d_%.1f_%.1f" % [0, md.pos.x, md.pos.z]
			occupied[key] = true
	# Find first empty spawn point (by index)
	for pt: Vector3 in spawn_pts:
		var key := "0_%.1f_%.1f" % [pt.x, pt.z]
		if not occupied.has(key):
			var md := Entities.MoteData.new()
			md.id = rng.next_mote_id()
			md.pos = pt
			md.kind = "random"
			motes.append(md)
			return
	# No empty point → skip

func _step_spawn_shades(tick: int) -> void:
	if sim_tick < _next_shade_spawn_tick:
		return
	var shade_max: int = world.get("shade_max", 6)
	if shades.size() >= shade_max:
		_next_shade_spawn_tick += world.get("shade_spawn_interval_ticks", 480)
		return
	var spawn_pts: Array = world.get("shade_spawn_points", [])
	if spawn_pts.is_empty():
		return
	# How many to spawn this batch?
	var count := 1
	if not _shade_initial_spawned:
		count = world.get("shade_spawn_first_count", 2)
		_shade_initial_spawned = true
	var spawned := 0
	for _i in range(count):
		if shades.size() >= shade_max:
			break
		# Pick valid spawn point: >=15m from player
		var valid_pts: Array = []
		for pt: Vector3 in spawn_pts:
			var dx: float = player.pos.x - pt.x
			var dz: float = player.pos.z - pt.z
			if sqrt(dx*dx+dz*dz) >= 15.0:
				valid_pts.append(pt)
		if valid_pts.is_empty():
			break
		var idx := rng.randi_range(0, valid_pts.size() - 1)
		var spawn_pos: Vector3 = valid_pts[idx]
		var sd := Entities.ShadeData.new()
		sd.id = rng.next_shade_id()
		sd.pos = spawn_pos
		sd.state = Entities.SHADE_SPAWNING
		sd.state_ticks_left = 1
		shades.append(sd)
		bus.record(tick, "shade_spawned", {"id": sd.id})
		spawned += 1
	_next_shade_spawn_tick += world.get("shade_spawn_interval_ticks", 480)

func _step_spawn_drifters(tick: int) -> void:
	if _next_drifter_spawn_idx >= _drifter_spawn_ticks.size():
		return
	var next_tick: int = _drifter_spawn_ticks[_next_drifter_spawn_idx]
	if sim_tick < next_tick:
		return
	_next_drifter_spawn_idx += 1
	# Check cap: max 2 concurrent drifters
	var active_count := 0
	for dr: Entities.DrifterData in drifters:
		if dr.state != Entities.DRIFTER_REMOVED:
			active_count += 1
	if active_count >= 2:
		return
	# Spawn on mist point (OPEN-B15: for now use random position near sea)
	var mist_pts: Array = world.get("mist_spawn_points", [])
	var spawn_pos: Vector3
	if mist_pts.is_empty():
		var angle := rng.randf_range(0.0, TAU)
		spawn_pos = Vector3(35.0 * cos(angle), 2.0, 35.0 * sin(angle))
	else:
		var idx := rng.randi_range(0, mist_pts.size() - 1)
		spawn_pos = mist_pts[idx]
		spawn_pos.y = 2.0
	var dr := Entities.DrifterData.new()
	dr.id = rng.next_drifter_id()
	dr.pos = spawn_pos
	dr.heading_deg = rng.randf_range(0.0, 360.0)
	drifters.append(dr)

# ── STEP 11: terminal conditions ─────────────────────────────
func _check_terminal(tick: int) -> void:
	if state == "won" or state == "lost":
		return
	# TICKET-03: dawn survival replaces early all_lit win
	# Priority: no_flames > dawn_survived > dawn
	if player.flames <= 0:
		state = "lost"
		bus.record(tick, "game_over", {"result": "lost", "reason": "no_flames"})
		return
	if time_left_s() <= 0.0:
		# Count lit lanterns at dawn tick
		var lit_count := 0
		for ld: Entities.LanternData in lanterns:
			if ld.lit:
				lit_count += 1
		var required := required_lit()
		if lit_count >= required:
			# Dawn survival win: score per lit lantern (fuel) + flames
			for ld: Entities.LanternData in lanterns:
				if ld.lit:
					var fuel_now := float(ld.fuel_units) / 60.0
					score += cfg.score_per_lantern_at_dawn + floori(fuel_now)
			score += cfg.score_per_flame_left * player.flames
			state = "won"
			bus.record(tick, "game_over", {"result": "won", "reason": "dawn_survived"})
		else:
			state = "lost"
			bus.record(tick, "game_over", {"result": "lost", "reason": "dawn"})

# ── Snapshot ──────────────────────────────────────────────────
func snapshot() -> Dictionary:
	var lantern_arr: Array = []
	for ld: Entities.LanternData in lanterns:
		lantern_arr.append({
			"id": ld.id,
			"pos": _vec3(ld.pos),
			"lit": ld.lit,
			"deposited": ld.deposited,
			"fuel": _r1(float(ld.fuel_units) / 60.0),
			"ever_lit": ld.ever_lit,
			"relit_count": ld.relit_count
		})
	var shade_arr: Array = []
	for sd: Entities.ShadeData in shades:
		shade_arr.append({
			"id": sd.id,
			"pos": _vec3(sd.pos),
			"state": sd.state
		})
	var motes_active := 0
	var mote_arr: Array = []
	for md: Entities.MoteData in motes:
		if md.active:
			motes_active += 1
			mote_arr.append({
				"id": md.id,
				"pos": _vec3(md.pos),
				"kind": md.kind,
				"ttl_s": _r3(md.ttl_ticks / TICK_RATE) if md.ttl_ticks > 0 else 0.0
			})
	var drifter_arr: Array = []
	for dr: Entities.DrifterData in drifters:
		if dr.state != Entities.DRIFTER_REMOVED:
			drifter_arr.append({
				"id": dr.id,
				"pos": _vec3(dr.pos),
				"state": dr.state,
				"stolen": dr.stolen
			})
	var charm_arr: Array = []
	for c: Entities.CharmData in charms:
		charm_arr.append({
			"id": c.id,
			"available": c.available,
			"respawn_s": _r3(c.respawn_ticks_left / TICK_RATE)
		})
	var snap := {
		"type": "snapshot",
		"tick": executed_ticks,
		"sim_tick": sim_tick,
		"night": night,
		"state": state,
		"time_left_s": _r3(time_left_s()),
		"score": score,
		"wind": {
			"active": wind_active,
			"dir_deg": _r3(wind_dir_deg)
		},
		"player": {
			"pos": _vec3(player.pos),
			"vel": _vec3(player.vel),
			"flames": player.flames,
			"carried": player.carried,
			"capacity": player.capacity,
			"grounded": player.grounded,
			"invuln": player.invuln_ticks,
			"dash_cd_s": _r3(player.dash_cd_ticks / TICK_RATE),
			"pulse_cd_s": _r3(player.pulse_cd_ticks / TICK_RATE),
			"charm_s": _r3(player.charm_ticks / TICK_RATE)
		},
		"lanterns": lantern_arr,
		"shades": shade_arr,
		"motes_active": motes_active,
		"motes": mote_arr,
		"drifters": drifter_arr,
		"charms": charm_arr,
	}
	return snap

func _vec3(v: Vector3) -> Array:
	return [_r3(v.x), _r3(v.y), _r3(v.z)]

static func _r3(x: float) -> float:
	return round(x * 1000.0) / 1000.0
