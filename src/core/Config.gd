# Config.gd — Single source of truth for tuning values (Contract v1.1).
# Loads game.contract.json once; exposes all tuning fields.
# No Node3D / display dependency.
class_name Config
extends RefCounted

# ── Movement ─────────────────────────────────────────────────
var player_speed: float          # 6.0 m/s  [REQ TICKET-02]
var player_accel_s: float        # <= 0.1 s to reach/stop [REQ TICKET-02]
var jump_vel_y: float            # 7.0 m/s  [REQ TICKET-02]
var gravity: float               # -20.0 m/s² [REQ TICKET-02]
var dash_speed: float            # 14.0 m/s [REQ TICKET-02]
var dash_duration_s: float       # 0.2 s    [REQ TICKET-02]
var dash_cooldown_s: float       # 1.5 s    [REQ TICKET-02]

# ── Mote ────────────────────────────────────────────────────
var carry_capacity: int          # 10        [REQ TICKET-02]
var pickup_radius: float         # 1.0 m     [REQ TICKET-02]
var pickup_height_m: float       # 1.5 m vertical tolerance [REQ TICKET-02]
var mote_initial_count: int      # 20        [REQ TICKET-02]
var mote_cap: int                # 30        [REQ TICKET-02]
var mote_spawn_interval_ticks: int # 240     [REQ TICKET-02]
var mote_drop_ttl_ticks: int     # 480 tick TTL for dropped motes [REQ TICKET-02]
var mote_drop_ring_min_m: float  # 1.5 m inner radius scatter  [REQ TICKET-02]
var mote_drop_ring_max_m: float  # 2.5 m outer radius scatter  [REQ TICKET-02]

# ── Lantern ──────────────────────────────────────────────────
var lantern_cost: int            # 10        [REQ TICKET-02]
var lantern_count_night1: int    # 5         [REQ both]
var interact_radius: float       # 2.0 m     [REQ TICKET-02]
var safe_radius: float           # 6.0 m     [REQ TICKET-02]
var safe_push_ticks: int         # 30 tick push-out [REQ TICKET-02]

# ── Pulse ────────────────────────────────────────────────────
var pulse_cost: int              # 3 motes   [REQ TICKET-02]
var pulse_radius: float          # 5.0 m     [REQ TICKET-02]
var pulse_center_height_m: float # 0.8 m above foot [REQ TICKET-02]
var pulse_stun_ticks: int        # 120 ticks [REQ TICKET-02]
var pulse_push_m: float          # 4.0 m total [REQ TICKET-02]
var pulse_push_ticks: int        # 15 ticks for push [REQ TICKET-02]
var pulse_cooldown_s: float      # 3.0 s     [REQ TICKET-02]

# ── Shade ────────────────────────────────────────────────────
var shade_speed: float           # 4.0 m/s   [REQ TICKET-02]
var shade_speed_night3: float    # 4.5 m/s   [REQ TICKET-02]
var shade_detect_m: float        # 12.0 m    [REQ TICKET-02]
var shade_abandon_m: float       # 18.0 m    [REQ TICKET-02]
var shade_hit_radius: float      # 1.0 m XZ  [REQ TICKET-02]
var shade_hit_height_m: float    # 1.5 m vertical [REQ TICKET-02]
var shade_recoil_m: float        # 2.0 m total [REQ TICKET-02]
var shade_recoil_ticks: int      # 60 ticks  [REQ TICKET-02]

# ── Night durations ──────────────────────────────────────────
var night1_duration_s: float     # 300 s     [REQ TICKET-02]
var night2_duration_s: float     # 330 s     [REQ TICKET-02]
var night3_duration_s: float     # 360 s     [REQ TICKET-02]

# ── Player health ────────────────────────────────────────────
var flames: int                  # 3         [REQ TICKET-02]
var invuln_ticks: int            # 90 ticks  [REQ TICKET-02]
var hit_drop_ratio: float        # 0.5 — floor(carried/2) [REQ TICKET-02]

# ── Fall ─────────────────────────────────────────────────────
var fall_enabled: bool           # true in v1.1 [REQ TICKET-02]
var fall_y_threshold: float      # -10.0 m   [REQ TICKET-02]
var fall_wait_ticks: int         # 60 ticks  [REQ TICKET-02]

# ── Charm (Bùa Gió) ──────────────────────────────────────────
var charm_duration_ticks: int    # 600 ticks [REQ TICKET-02]
var charm_speed: float           # 7.2 m/s   [REQ TICKET-02]
var charm_respawn_ticks: int     # 2700 ticks [REQ TICKET-02]

# ── Drifter (Gió Lạc) ────────────────────────────────────────
var drifter_speed_idle: float    # 2.0 m/s   [REQ TICKET-02]
var drifter_speed_chase: float   # 7.0 m/s   [REQ TICKET-02]
var drifter_speed_flee: float    # 7.0 m/s   [REQ TICKET-02]
var drifter_detect_m: float      # 15.0 m    [REQ TICKET-02]
var drifter_steal_max_motes: int # 3 max motes stolen per hit [REQ TICKET-02]
var drifter_steal_radius: float  # 1.2 m XZ  [REQ TICKET-02]
var drifter_flee_ticks: int      # 240 ticks [REQ TICKET-02]
var drifter_carried_min: int     # 5 motes threshold [REQ TICKET-02]

# ── Wind (Night 3) ───────────────────────────────────────────
var wind_cycle_ticks: int        # 1800 (30 s) [REQ TICKET-02]
var wind_warning_ticks: int      # 120 (2 s before active) [REQ + DECIDE C5]
var wind_active_ticks: int       # 300 (5 s) [REQ TICKET-02]
var wind_speed: float            # 2.0 m/s   [REQ TICKET-02]

# ── Lantern fuel (TICKET-03 v1.2) ────────────────────────────
var fuel_max: int                 # 100       [REQ TICKET-03]
var fuel_decay_per_s: float      # 1.0       [REQ TICKET-03]
var fuel_per_mote: int           # 10        [REQ TICKET-03]
var relight_cost: int            # 5 motes   [REQ TICKET-03]
var win_ratio: float             # 0.6       [REQ TICKET-03]
var drain_per_s: float           # 5         [REQ TICKET-03]
var low_fuel_threshold: int      # 30        [REQ TICKET-03]
var capacity_max: int            # 20        [REQ TICKET-03]
var shade_drain_radius: float    # 2.0 m XZ  [REQ TICKET-03]

# ── Score ────────────────────────────────────────────────────
# Canonical names from game.contract.json score object (v1.2).
var score_per_mote: int          # 5 per mote deposited (light, relight, refuel)
var score_per_lantern: int       # 100 first light
var score_per_relight: int       # 40 relight
var score_per_stun: int          # 5 pulse hit on normal shade
var score_per_stun_drain: int    # 15 pulse hit on draining shade
var score_per_lantern_at_dawn: int  # 50 per lit lantern at dawn win
var score_per_flame_left: int    # 50 per flame at dawn win

# raw contract fields
var contract_version: String
var team: String

# ── Required tuning keys (must be present in v1.1 contract) ──────────────
const _REQUIRED_TUNING: Array[String] = [
	"player_speed", "player_accel_s", "carry_capacity", "capacity_max", "lantern_cost",
	"relight_cost", "fuel_max", "fuel_decay_per_s", "fuel_per_mote",
	"low_fuel_threshold", "drain_per_s", "win_ratio", "shade_drain_radius",
	"lantern_count_night1", "pickup_radius", "pickup_height_m", "interact_radius",
	"pulse_cost", "pulse_radius", "pulse_center_height_m", "pulse_stun_ticks",
	"pulse_push_m", "pulse_push_ticks", "pulse_cooldown_s",
	"safe_radius", "safe_push_ticks",
	"shade_speed", "shade_speed_night3", "shade_detect_m", "shade_abandon_m",
	"shade_hit_radius", "shade_hit_height_m", "shade_recoil_m", "shade_recoil_ticks",
	"night1_duration_s", "night2_duration_s", "night3_duration_s",
	"flames", "invuln_ticks", "hit_drop_ratio",
	"mote_drop_ttl_ticks", "mote_drop_ring_min_m", "mote_drop_ring_max_m",
	"mote_initial_count", "mote_cap", "mote_spawn_interval_ticks",
	"fall_enabled", "fall_y_threshold", "fall_wait_ticks",
	"jump_vel_y", "gravity", "dash_speed", "dash_duration_s", "dash_cooldown_s",
	"charm_duration_ticks", "charm_speed", "charm_respawn_ticks",
	"drifter_speed_idle", "drifter_speed_chase", "drifter_speed_flee",
	"drifter_detect_m", "drifter_steal_max_motes", "drifter_steal_radius",
	"drifter_flee_ticks", "drifter_carried_min",
	"wind_cycle_ticks", "wind_warning_ticks", "wind_active_ticks", "wind_speed",
]
const _REQUIRED_SCORE: Array[String] = [
	"per_mote", "per_lantern", "per_relight", "per_stun", "per_stun_drain",
	"per_lantern_at_dawn", "per_flame_left",
]

# ── type specs: field_name -> ("float" | "int" | "bool") ──────────────────
const _TYPE_SPECS: Dictionary = {
	# Movement (float)
	"player_speed": "float", "player_accel_s": "float",
	"jump_vel_y": "float", "gravity": "float",
	"dash_speed": "float", "dash_duration_s": "float", "dash_cooldown_s": "float",
	# Mote (mixed)
	"carry_capacity": "int", "pickup_radius": "float", "pickup_height_m": "float",
	"mote_initial_count": "int", "mote_cap": "int", "mote_spawn_interval_ticks": "int",
	"mote_drop_ttl_ticks": "int", "mote_drop_ring_min_m": "float", "mote_drop_ring_max_m": "float",
	# Lantern + fuel (mixed)
	"lantern_cost": "int", "lantern_count_night1": "int",
	"interact_radius": "float", "safe_radius": "float", "safe_push_ticks": "int",
	"relight_cost": "int", "fuel_max": "int", "fuel_decay_per_s": "float",
	"fuel_per_mote": "int", "low_fuel_threshold": "int", "drain_per_s": "float",
	"win_ratio": "float", "shade_drain_radius": "float", "capacity_max": "int",
	# Pulse (mixed)
	"pulse_cost": "int", "pulse_radius": "float", "pulse_center_height_m": "float",
	"pulse_stun_ticks": "int", "pulse_push_m": "float", "pulse_push_ticks": "int",
	"pulse_cooldown_s": "float",
	# Shade (mixed)
	"shade_speed": "float", "shade_speed_night3": "float",
	"shade_detect_m": "float", "shade_abandon_m": "float",
	"shade_hit_radius": "float", "shade_hit_height_m": "float",
	"shade_recoil_m": "float", "shade_recoil_ticks": "int",
	# Night (float)
	"night1_duration_s": "float", "night2_duration_s": "float", "night3_duration_s": "float",
	# Player health (mixed)
	"flames": "int", "invuln_ticks": "int", "hit_drop_ratio": "float",
	# Fall (mixed)
	"fall_enabled": "bool", "fall_y_threshold": "float", "fall_wait_ticks": "int",
	# Charm (mixed)
	"charm_duration_ticks": "int", "charm_speed": "float", "charm_respawn_ticks": "int",
	# Drifter (mixed)
	"drifter_speed_idle": "float", "drifter_speed_chase": "float", "drifter_speed_flee": "float",
	"drifter_detect_m": "float", "drifter_steal_max_motes": "int", "drifter_steal_radius": "float",
	"drifter_flee_ticks": "int", "drifter_carried_min": "int",
	# Wind (mixed)
	"wind_cycle_ticks": "int", "wind_warning_ticks": "int",
	"wind_active_ticks": "int", "wind_speed": "float",
}

# ── Helper: validate and convert value to expected type ───────────────────
static func _type_name(v: Variant) -> String:
	match typeof(v):
		TYPE_NIL: return "null"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_BOOL: return "bool"
		TYPE_STRING: return "string"
		TYPE_DICTIONARY: return "dict"
		TYPE_ARRAY: return "array"
		_: return "unknown(%d)" % typeof(v)

static func _coerce_value(value: Variant, expected_type: String, field_name: String) -> Variant:
	match expected_type:
		"float":
			# float accepts JSON int or float
			if value is int or value is float:
				return float(value)
			push_error("Config: field '%s' type error: expected float, got %s" % [
				field_name, _type_name(value)])
			return null
		"int":
			# int: accept int directly, or float if it's an exact integer (JSON parse gives floats)
			if value is int:
				return int(value)
			if value is float:
				# Check for special float values and fractional parts
				if is_nan(value) or is_inf(value):
					push_error("Config: field '%s' type error: float is NaN or Inf" % field_name)
					return null
				if value != floor(value):
					push_error("Config: field '%s' type error: expected int, got float %f (not whole)" % [
						field_name, value])
					return null
				# Accept whole-valued float and convert to int
				return int(value)
			push_error("Config: field '%s' type error: expected int, got %s" % [
				field_name, _type_name(value)])
			return null
		"bool":
			# bool requires boolean
			if value is bool:
				return bool(value)
			push_error("Config: field '%s' type error: expected bool, got %s" % [
				field_name, _type_name(value)])
			return null
	push_error("Config: _coerce_value unknown type '%s'" % expected_type)
	return null

# ── loader ───────────────────────────────────────────────────
static func load_from_file(path: String) -> Config:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Config: cannot open '%s'" % path)
		return null
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	var err := json.parse(txt)
	if err != OK:
		push_error("Config: JSON parse error in '%s' at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()])
		return null
	var d: Variant = json.get_data()

	# Validate root is dict
	if not (d is Dictionary):
		push_error("Config: root must be dict, got %s" % typeof(d))
		return null

	# Validate contract version — must be "1.1" or "1.2"
	var ver: Variant = d.get("contract_version", null)
	if not (ver is String):
		push_error("Config: contract_version must be String, got %s" % typeof(ver))
		return null
	if ver != "1.1" and ver != "1.2":
		push_error("Config: contract_version must be '1.1' or '1.2', got '%s'" % ver)
		return null

	var t: Variant = d.get("tuning", null)
	if not (t is Dictionary):
		push_error("Config: tuning must be dict, got %s" % typeof(t))
		return null

	var sc: Variant = t.get("score", null)
	if not (sc is Dictionary):
		push_error("Config: tuning['score'] must be dict, got %s" % typeof(sc))
		return null

	# Validate required tuning keys
	for key: String in _REQUIRED_TUNING:
		if not t.has(key):
			push_error("Config: required tuning key '%s' is missing" % key)
			return null

	# Validate required score keys
	for key: String in _REQUIRED_SCORE:
		if not sc.has(key):
			push_error("Config: required score['%s'] is missing" % key)
			return null

	var c := Config.new()
	c.contract_version = ver
	c.team = str(d.get("team", ""))

	# Load and type-validate all tuning fields
	for key: String in _REQUIRED_TUNING:
		var val: Variant = t[key]
		var expected_type: String = _TYPE_SPECS.get(key, "?")
		var coerced: Variant = _coerce_value(val, expected_type, key)
		if coerced == null:
			return null
		# Assign to corresponding var
		match key:
			"player_speed": c.player_speed = coerced
			"player_accel_s": c.player_accel_s = coerced
			"carry_capacity": c.carry_capacity = coerced
			"lantern_cost": c.lantern_cost = coerced
			"lantern_count_night1": c.lantern_count_night1 = coerced
			"pickup_radius": c.pickup_radius = coerced
			"pickup_height_m": c.pickup_height_m = coerced
			"interact_radius": c.interact_radius = coerced
			"pulse_cost": c.pulse_cost = coerced
			"pulse_radius": c.pulse_radius = coerced
			"pulse_center_height_m": c.pulse_center_height_m = coerced
			"pulse_stun_ticks": c.pulse_stun_ticks = coerced
			"pulse_push_m": c.pulse_push_m = coerced
			"pulse_push_ticks": c.pulse_push_ticks = coerced
			"pulse_cooldown_s": c.pulse_cooldown_s = coerced
			"safe_radius": c.safe_radius = coerced
			"safe_push_ticks": c.safe_push_ticks = coerced
			"shade_speed": c.shade_speed = coerced
			"shade_speed_night3": c.shade_speed_night3 = coerced
			"shade_detect_m": c.shade_detect_m = coerced
			"shade_abandon_m": c.shade_abandon_m = coerced
			"shade_hit_radius": c.shade_hit_radius = coerced
			"shade_hit_height_m": c.shade_hit_height_m = coerced
			"shade_recoil_m": c.shade_recoil_m = coerced
			"shade_recoil_ticks": c.shade_recoil_ticks = coerced
			"night1_duration_s": c.night1_duration_s = coerced
			"night2_duration_s": c.night2_duration_s = coerced
			"night3_duration_s": c.night3_duration_s = coerced
			"flames": c.flames = coerced
			"invuln_ticks": c.invuln_ticks = coerced
			"hit_drop_ratio": c.hit_drop_ratio = coerced
			"mote_drop_ttl_ticks": c.mote_drop_ttl_ticks = coerced
			"mote_drop_ring_min_m": c.mote_drop_ring_min_m = coerced
			"mote_drop_ring_max_m": c.mote_drop_ring_max_m = coerced
			"mote_initial_count": c.mote_initial_count = coerced
			"mote_cap": c.mote_cap = coerced
			"mote_spawn_interval_ticks": c.mote_spawn_interval_ticks = coerced
			"fall_enabled": c.fall_enabled = coerced
			"fall_y_threshold": c.fall_y_threshold = coerced
			"fall_wait_ticks": c.fall_wait_ticks = coerced
			"jump_vel_y": c.jump_vel_y = coerced
			"gravity": c.gravity = coerced
			"dash_speed": c.dash_speed = coerced
			"dash_duration_s": c.dash_duration_s = coerced
			"dash_cooldown_s": c.dash_cooldown_s = coerced
			"charm_duration_ticks": c.charm_duration_ticks = coerced
			"charm_speed": c.charm_speed = coerced
			"charm_respawn_ticks": c.charm_respawn_ticks = coerced
			"drifter_speed_idle": c.drifter_speed_idle = coerced
			"drifter_speed_chase": c.drifter_speed_chase = coerced
			"drifter_speed_flee": c.drifter_speed_flee = coerced
			"drifter_detect_m": c.drifter_detect_m = coerced
			"drifter_steal_max_motes": c.drifter_steal_max_motes = coerced
			"drifter_steal_radius": c.drifter_steal_radius = coerced
			"drifter_flee_ticks": c.drifter_flee_ticks = coerced
			"drifter_carried_min": c.drifter_carried_min = coerced
			"wind_cycle_ticks": c.wind_cycle_ticks = coerced
			"wind_warning_ticks": c.wind_warning_ticks = coerced
			"wind_active_ticks": c.wind_active_ticks = coerced
			"wind_speed": c.wind_speed = coerced
			# Fuel/lantern (v1.2)
			"capacity_max": c.capacity_max = coerced
			"relight_cost": c.relight_cost = coerced
			"fuel_max": c.fuel_max = coerced
			"fuel_decay_per_s": c.fuel_decay_per_s = coerced
			"fuel_per_mote": c.fuel_per_mote = coerced
			"low_fuel_threshold": c.low_fuel_threshold = coerced
			"drain_per_s": c.drain_per_s = coerced
			"win_ratio": c.win_ratio = coerced
			"shade_drain_radius": c.shade_drain_radius = coerced

	# Score — validate and load
	for key: String in _REQUIRED_SCORE:
		var val: Variant = sc[key]
		var expected_type: String = "int"  # all score fields are int
		var coerced: Variant = _coerce_value(val, expected_type, "score['%s']" % key)
		if coerced == null:
			return null
		match key:
			"per_mote": c.score_per_mote = coerced
			"per_lantern": c.score_per_lantern = coerced
			"per_relight": c.score_per_relight = coerced
			"per_stun": c.score_per_stun = coerced
			"per_stun_drain": c.score_per_stun_drain = coerced
			"per_lantern_at_dawn": c.score_per_lantern_at_dawn = coerced
			"per_flame_left": c.score_per_flame_left = coerced

	return c

# ── Helpers ──────────────────────────────────────────────────

# Duration of a given night in seconds. Errors on unknown night number.
func night_duration_s(night: int) -> float:
	match night:
		1: return night1_duration_s
		2: return night2_duration_s
		3: return night3_duration_s
	push_error("Config.night_duration_s: unknown night %d (must be 1, 2 or 3)" % night)
	return -1.0

# Shade speed for a given night. Errors on unknown night number.
func night_shade_speed(night: int) -> float:
	match night:
		1, 2: return shade_speed
		3:    return shade_speed_night3
	push_error("Config.night_shade_speed: unknown night %d (must be 1, 2 or 3)" % night)
	return -1.0
