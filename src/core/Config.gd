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
var build_cmd: String
var run_cmd: String
var headless_cmd: String
var bench_cmd: String   # required from contract v1.3
var soak_cmd: String    # required from contract v1.3

# Last validation error (field path included); empty after a successful load.
static var last_error: String = ""

const SUPPORTED_VERSIONS: Array[String] = ["1.1", "1.2", "1.3"]

# ── Required tuning keys (must be present in the v1.2+ contract) ──────────────
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
			_fail("Config: field '%s' type error: expected float, got %s" % [
				field_name, _type_name(value)])
			return null
		"int":
			# int: accept int directly, or float if it's an exact integer (JSON parse gives floats)
			if value is int:
				return int(value)
			if value is float:
				# Check for special float values and fractional parts
				if is_nan(value) or is_inf(value):
					_fail("Config: field '%s' type error: float is NaN or Inf" % field_name)
					return null
				if value != floor(value):
					_fail("Config: field '%s' type error: expected int, got float %f (not whole)" % [
						field_name, value])
					return null
				# Accept whole-valued float and convert to int
				return int(value)
			_fail("Config: field '%s' type error: expected int, got %s" % [
				field_name, _type_name(value)])
			return null
		"bool":
			# bool requires boolean
			if value is bool:
				return bool(value)
			_fail("Config: field '%s' type error: expected bool, got %s" % [
				field_name, _type_name(value)])
			return null
	push_error("Config: _coerce_value unknown type '%s'" % expected_type)
	return null

# ── loader ───────────────────────────────────────────────────
static func _fail(msg: String) -> Config:
	last_error = msg
	push_error(msg)
	return null

static func load_from_file(path: String) -> Config:
	last_error = ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return _fail("Config: cannot open '%s'" % path)
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	var err := json.parse(txt)
	if err != OK:
		return _fail("Config: JSON parse error in '%s' at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()])
	return parse_dict(json.get_data())

# Strict validation of an already-parsed contract. Returns null (and sets last_error)
# on the first problem; the message always names the offending field path.
static func parse_dict(d: Variant) -> Config:
	last_error = ""
	if not (d is Dictionary):
		return _fail("Config: root must be dict, got %s" % _type_name(d))
	var ver: Variant = d.get("contract_version", null)
	if not (ver is String):
		return _fail("Config: contract_version must be String, got %s" % _type_name(ver))
	if not SUPPORTED_VERSIONS.has(ver):
		return _fail("Config: contract_version must be one of %s, got '%s'" % [SUPPORTED_VERSIONS, ver])
	var t: Variant = d.get("tuning", null)
	if not (t is Dictionary):
		return _fail("Config: tuning must be dict, got %s" % _type_name(t))
	var sc: Variant = t.get("score", null)
	if not (sc is Dictionary):
		return _fail("Config: tuning.score must be dict, got %s" % _type_name(sc))

	var root_strings: Array[String] = ["team", "build_cmd", "run_cmd", "headless_cmd"]
	if ver == "1.3":
		root_strings.append("bench_cmd")
		root_strings.append("soak_cmd")
	for key: String in root_strings:
		if not d.has(key):
			return _fail("Config: required field '%s' is missing" % key)
		if not (d[key] is String):
			return _fail("Config: field '%s' type error: expected string, got %s" % [key, _type_name(d[key])])
	for key: String in _REQUIRED_TUNING:
		if not t.has(key):
			return _fail("Config: required field 'tuning.%s' is missing" % key)
	for key: String in _REQUIRED_SCORE:
		if not sc.has(key):
			return _fail("Config: required field 'tuning.score.%s' is missing" % key)

	var c := Config.new()
	c.contract_version = ver
	c.team = d["team"]
	c.build_cmd = d["build_cmd"]
	c.run_cmd = d["run_cmd"]
	c.headless_cmd = d["headless_cmd"]
	if ver == "1.3":
		c.bench_cmd = d["bench_cmd"]
		c.soak_cmd = d["soak_cmd"]

	for key: String in _REQUIRED_TUNING:
		var coerced: Variant = _coerce_value(t[key], _TYPE_SPECS.get(key, "?"), "tuning." + key)
		if coerced == null:
			return null
		c.set(key, coerced)

	for key: String in _REQUIRED_SCORE:
		var coerced: Variant = _coerce_value(sc[key], "int", "tuning.score." + key)
		if coerced == null:
			return null
		c.set("score_" + key, coerced)
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
