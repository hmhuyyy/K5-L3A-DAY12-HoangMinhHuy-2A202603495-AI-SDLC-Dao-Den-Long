# WorldDefs.gd — Night map definitions (Phase 2).
# Three islands: Bến, Cau, Chuong. Pure data + ground queries.
# World angle convention: x = r·cos(a), z = r·sin(a), 0°=+X, 90°=+Z.
class_name WorldDefs
extends RefCounted

const TICK_RATE := 60.0

# ── Night 1 — Đảo Bến: circle r=40 ─────────────────────────────
static func night1() -> Dictionary:
	return {
		"lanterns": [
			{"id": "L1", "pos": Vector3(0.0, 0.0, 25.0)},
			{"id": "L2", "pos": Vector3(23.8, 0.0, 7.7)},
			{"id": "L3", "pos": Vector3(14.7, 0.0, -20.2)},
			{"id": "L4", "pos": Vector3(-14.7, 0.0, -20.2)},
			{"id": "L5", "pos": Vector3(-23.8, 0.0, 7.7)},
		],
		# Spawn points: 8 inner r=12 (each 45°) + 16 outer r=33 (each 22.5°)
		"mote_spawn_points": _ring_points(12.0, 8, 0.0, 45.0, 0.0) \
			+ _ring_points(33.0, 16, 0.0, 22.5, 0.0),
		# Initial 20: In01-In08 + Out01-Out12 (angles 0..247.5). C4 approved.
		"mote_initial_indices": range(0, 20),
		"shade_spawn_points": _ring_points(37.0, 12, 15.0, 30.0, 0.0),
		"shade_spawn_first_tick": 300,
		"shade_spawn_first_count": 2,
		"shade_spawn_interval_ticks": 480,
		"shade_max": 6,
		"bounce_pads": [],
		"drifter_spawn_ticks": [],        # Night 1: no drifters
		"mist_spawn_points": [],          # Night 1: no mist points
		"charms": [],
		"wind_enabled": false,
		"islands": [
			{"type": "circle", "center": Vector3.ZERO, "radius": 40.0},
		],
	}

# ── Night 2 — Đảo Cau: two islands + rope bridge + pads ────────
static func night2() -> Dictionary:
	var motes_a := _ring_points(10.0, 4, 0.0, 90.0, 0.0) \
		+ _ring_points(22.0, 8, 0.0, 45.0, 0.0)
	var motes_b := _ring_points(10.0, 4, 0.0, 90.0, 70.0) \
		+ _ring_points(22.0, 8, 0.0, 45.0, 70.0)
	# Initial 20: 10 per island (4 inner + 6 outer each)
	var initial: Array = []
	for i in range(10):
		initial.append(i)                 # island A first 10
		initial.append(10 + i)            # island B first 10
	return {
		"lanterns": [
			{"id": "L1", "pos": Vector3(0.0, 0.0, 20.0)},
			{"id": "L2", "pos": Vector3(17.0, 0.0, -10.0)},
			{"id": "L3", "pos": Vector3(-17.0, 0.0, -10.0)},
			{"id": "L4", "pos": Vector3(70.0, 0.0, 20.0)},
			{"id": "L5", "pos": Vector3(87.0, 0.0, -10.0)},
			{"id": "L6", "pos": Vector3(53.0, 0.0, -10.0)},
		],
		"mote_spawn_points": motes_a + motes_b,
		"mote_initial_indices": initial,
		"shade_spawn_points": _ring_points(26.0, 8, 22.5, 45.0, 0.0) \
			+ _ring_points(26.0, 8, 22.5, 45.0, 70.0),
		"shade_spawn_first_tick": 300,
		"shade_spawn_first_count": 2,
		"shade_spawn_interval_ticks": 420,   # 7 s
		"shade_max": 8,
		# Pads: (20,0,18) on island A targets island B center (70,0,0);
		#        (50,0,-18) on island B targets island A center (0,0,0).
		"bounce_pads": [
			{"pos": Vector3(20.0, 0.0, 18.0), "vel_y": 14.0,
			 "dir": Vector2(70.0 - 20.0, 0.0 - 18.0).normalized(), "h_speed": 24.0},
			{"pos": Vector3(50.0, 0.0, -18.0), "vel_y": 14.0,
			 "dir": Vector2(0.0 - 50.0, 0.0 + 18.0).normalized(), "h_speed": 24.0},
		],
		"drifter_spawn_ticks": [1200, 2400],  # max 2 concurrent
		"mist_spawn_points": _ring_points(24.0, 6, 30.0, 60.0, 35.0),  # over the sea gap
		"charms": [
			{"id": "C1", "pos": Vector3(35.0, 0.0, 0.0)},
		],
		"wind_enabled": false,
		"islands": [
			{"type": "circle", "center": Vector3(0.0, 0.0, 0.0), "radius": 28.0},
			{"type": "circle", "center": Vector3(70.0, 0.0, 0.0), "radius": 28.0},
			{"type": "bridge", "x_range": [26.0, 44.0], "z_range": [-2.0, 2.0]},
		],
	}

# ── Night 3 — Đảo Chuông: 3 tiers + ramps + pad + tower ──────
static func night3() -> Dictionary:
	var ground_pts := _ring_points(34.0, 18, 0.0, 20.0, 0.0)
	var tier1_pts := _ring_points(18.0, 8, 20.0, 20.0, 0.0)   # 20..160° → z>0
	var tier2_pts := _ring_points(5.0, 4, 45.0, 90.0, 0.0)
	return {
		"lanterns": [
			{"id": "L1", "pos": Vector3(0.0, 6.0, 6.0)},
			{"id": "L2", "pos": Vector3(18.0, 3.0, 10.0)},
			{"id": "L3", "pos": Vector3(-18.0, 3.0, 10.0)},
			{"id": "L4", "pos": Vector3(35.0, 0.0, -10.0)},
			{"id": "L5", "pos": Vector3(-35.0, 0.0, -10.0)},
			{"id": "L6", "pos": Vector3(20.0, 0.0, -35.0)},
			{"id": "L7", "pos": Vector3(-20.0, 0.0, -35.0)},
		],
		"mote_spawn_points": ground_pts + tier1_pts + tier2_pts,  # 18+8+4 = 30
		"mote_initial_indices": range(20),  # first 20 (tier 0 ring first)
		"shade_spawn_points": _ring_points(43.0, 16, 0.0, 22.5, 0.0),
		"shade_spawn_first_tick": 300,
		"shade_spawn_first_count": 2,
		"shade_spawn_interval_ticks": 360,   # 6 s
		"shade_max": 10,
		# Pad at (0,3,13) on tier 1: vel_y 12, horizontal 8 m/s toward -Z → tier 2
		"bounce_pads": [
			{"pos": Vector3(0.0, 3.0, 13.0), "vel_y": 12.0,
			 "dir": Vector2(0.0, -1.0), "h_speed": 8.0},
		],
		"drifter_spawn_ticks": [1200, 2400],
		"mist_spawn_points": _ring_points(30.0, 6, 60.0, 60.0, 0.0),
		"charms": [
			{"id": "C1", "pos": Vector3(30.0, 0.0, 25.0)},
			{"id": "C2", "pos": Vector3(-30.0, 0.0, 25.0)},
		],
		"wind_enabled": true,
		"islands": [
			# Tier structure handled by ground_height query below.
			{"type": "tiers", "center": Vector3.ZERO, "radius": 45.0},
		],
	}

# ── Night lookup ──────────────────────────────────────────────
static func for_night(n: int) -> Dictionary:
	match n:
		1: return night1()
		2: return night2()
		3: return night3()
	push_error("WorldDefs.for_night: unknown night %d" % n)
	return night1()

# ── Ground height queries (XZ → Y) ────────────────────────────
# Night 1: 0 inside r=40, else fall.
# Night 2: 0 inside either circle or the bridge, else fall.
# Night 3: tier 2 (r<=8) → 6; tier 1 (12<=r<=24 && z>0) → 3; else 0 inside r=45.
#   Ramp angles 30°,150° r 24..30: linear 0→3 (approximated by tier1 zone
#   extension along the ramp; see _night3_ground for details).
static func ground_height(world: Dictionary, night: int, x: float, z: float) -> float:
	match night:
		1:
			if Vector2(x, z).length() <= 40.0:
				return 0.0
			return -999.0  # over the sea → fall
		2:
			if Vector2(x, z).length() <= 28.0:
				return 0.0
			var db := Vector2(x - 70.0, z)
			if db.length() <= 28.0:
				return 0.0
			# bridge: x in [26,44], z in [-2,2]
			if x >= 26.0 and x <= 44.0 and z >= -2.0 and z <= 2.0:
				return 0.0
			return -999.0
		3:
			return _night3_ground(x, z)
	push_error("WorldDefs.ground_height: unknown night %d" % night)
	return 0.0

static func _night3_ground(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	if r > 45.0:
		return -999.0
	# Tier 2: disc r<=8 at Y=6
	if r <= 8.0:
		return 6.0
	# Ramps at 30° and 150°: r 24..30, width 3 m along the radial line.
	# Approximation: within the angular wedge ±(width/2)/r of 30°/150° and
	# r in [24,30], height rises linearly from 0 (at r=30) to 3 (at r=24).
	var ang := rad_to_deg(atan2(z, x))
	if ang < 0.0:
		ang += 360.0
	for ramp_deg: float in [30.0, 150.0]:
		var d_ang := _ang_diff(ang, ramp_deg)
		# width 3 m at radius r → angular half-width = 1.5 / r
		if d_ang <= 1.5 / max(r, 1.0) * 57.2958 and r >= 24.0 and r <= 30.0:
			# linear: at r=30 → 0.0; at r=24 → 3.0
			return 3.0 * (30.0 - r) / 6.0
	# Tier 1: annulus 12..24 in the z>0 half
	if z > 0.0 and r >= 12.0 and r <= 24.0:
		return 3.0
	# Tower at tier-2 center: cylinder r<=2 at Y=6..14, top not walkable
	# (not climbable — treat as wall; ground query stays 6 inside r<=8).
	# Everything else: tier 0
	return 0.0

static func _ang_diff(a: float, b: float) -> float:
	var d: float = absf(a - b)
	if d > 180.0:
		d = 360.0 - d
	return d

# ── Helpers ───────────────────────────────────────────────────
# Points on a ring: radius r, count n, start angle, step, x-offset.
static func _ring_points(r: float, n: int, start_deg: float, step_deg: float, x_off: float) -> Array:
	var pts: Array = []
	for i in range(n):
		var a := deg_to_rad(start_deg + i * step_deg)
		pts.append(Vector3(r * cos(a) + x_off, 0.0, r * sin(a)))
	return pts

# Player spawn per night.
static func player_spawn(night: int) -> Vector3:
	return Vector3.ZERO  # all nights: (0,0,0) facing +Z
