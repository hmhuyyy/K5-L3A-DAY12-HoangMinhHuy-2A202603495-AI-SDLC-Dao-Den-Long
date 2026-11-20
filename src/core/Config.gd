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

# ── Score ────────────────────────────────────────────────────
# Canonical names from game.contract.json score object.
# Semantics: per_mote = per DEPOSITED mote (not pickup). [REQ TICKET-02 L67]
var score_per_mote: int          # 10 — awarded on deposit, not pickup
var score_per_lantern: int       # 100
var score_per_stun: int          # 5 per shade hit by pulse
var score_per_second_left: int   # 2 — applied as floor(time_left_s) * this
var score_per_flame_left: int    # 50

# ── Phase-1 compatibility aliases (temporary until GameSim is rewritten) ──
# GameSim Phase 1 references these names directly. These properties derive
# from the v1.1 canonical fields above. Remove when GameSim is updated.
var score_per_mote_deposited: int:  # alias → score_per_mote
	get: return score_per_mote
var pulse_stun_s: float:            # alias → pulse_stun_ticks / 60.0
	get: return pulse_stun_ticks / 60.0
var invuln_s: float:                # alias → invuln_ticks / 60.0
	get: return invuln_ticks / 60.0
var score_per_second_left_x2: int:  # alias → score_per_second_left
	get: return score_per_second_left

# raw contract fields
var contract_version: String
var team: String

# ── Required tuning keys (must be present in v1.1 contract) ──────────────
const _REQUIRED_TUNING: Array[String] = [
	"player_speed", "player_accel_s", "carry_capacity", "lantern_cost",
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
	"per_mote", "per_lantern", "per_stun", "per_second_left", "per_flame_left",
]

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
	var d: Dictionary = json.get_data()

	# Validate contract version — must be exactly "1.1"
	var ver: String = str(d.get("contract_version", ""))
	if ver != "1.1":
		push_error("Config: contract_version must be '1.1', got '%s'" % ver)
		return null

	var t: Dictionary = d.get("tuning", {})

	# Validate required tuning keys
	for key: String in _REQUIRED_TUNING:
		if not t.has(key):
			push_error("Config: required tuning key '%s' is missing" % key)
			return null

	var sc: Dictionary = t.get("score", {})
	for key: String in _REQUIRED_SCORE:
		if not sc.has(key):
			push_error("Config: required score key '%s' is missing" % key)
			return null

	var c := Config.new()
	c.contract_version = ver
	c.team = str(d.get("team", ""))

	# Movement
	c.player_speed    = float(t["player_speed"])
	c.player_accel_s  = float(t["player_accel_s"])
	c.jump_vel_y      = float(t["jump_vel_y"])
	c.gravity         = float(t["gravity"])
	c.dash_speed      = float(t["dash_speed"])
	c.dash_duration_s = float(t["dash_duration_s"])
	c.dash_cooldown_s = float(t["dash_cooldown_s"])

	# Mote
	c.carry_capacity            = int(t["carry_capacity"])
	c.pickup_radius             = float(t["pickup_radius"])
	c.pickup_height_m           = float(t["pickup_height_m"])
	c.mote_initial_count        = int(t["mote_initial_count"])
	c.mote_cap                  = int(t["mote_cap"])
	c.mote_spawn_interval_ticks = int(t["mote_spawn_interval_ticks"])
	c.mote_drop_ttl_ticks       = int(t["mote_drop_ttl_ticks"])
	c.mote_drop_ring_min_m      = float(t["mote_drop_ring_min_m"])
	c.mote_drop_ring_max_m      = float(t["mote_drop_ring_max_m"])

	# Lantern
	c.lantern_cost         = int(t["lantern_cost"])
	c.lantern_count_night1 = int(t["lantern_count_night1"])
	c.interact_radius      = float(t["interact_radius"])
	c.safe_radius          = float(t["safe_radius"])
	c.safe_push_ticks      = int(t["safe_push_ticks"])

	# Pulse
	c.pulse_cost            = int(t["pulse_cost"])
	c.pulse_radius          = float(t["pulse_radius"])
	c.pulse_center_height_m = float(t["pulse_center_height_m"])
	c.pulse_stun_ticks      = int(t["pulse_stun_ticks"])
	c.pulse_push_m          = float(t["pulse_push_m"])
	c.pulse_push_ticks      = int(t["pulse_push_ticks"])
	c.pulse_cooldown_s      = float(t["pulse_cooldown_s"])

	# Shade
	c.shade_speed        = float(t["shade_speed"])
	c.shade_speed_night3 = float(t["shade_speed_night3"])
	c.shade_detect_m     = float(t["shade_detect_m"])
	c.shade_abandon_m    = float(t["shade_abandon_m"])
	c.shade_hit_radius   = float(t["shade_hit_radius"])
	c.shade_hit_height_m = float(t["shade_hit_height_m"])
	c.shade_recoil_m     = float(t["shade_recoil_m"])
	c.shade_recoil_ticks = int(t["shade_recoil_ticks"])

	# Night durations
	c.night1_duration_s = float(t["night1_duration_s"])
	c.night2_duration_s = float(t["night2_duration_s"])
	c.night3_duration_s = float(t["night3_duration_s"])

	# Player health
	c.flames         = int(t["flames"])
	c.invuln_ticks   = int(t["invuln_ticks"])
	c.hit_drop_ratio = float(t["hit_drop_ratio"])

	# Fall
	c.fall_enabled     = bool(t["fall_enabled"])
	c.fall_y_threshold = float(t["fall_y_threshold"])
	c.fall_wait_ticks  = int(t["fall_wait_ticks"])

	# Charm
	c.charm_duration_ticks = int(t["charm_duration_ticks"])
	c.charm_speed          = float(t["charm_speed"])
	c.charm_respawn_ticks  = int(t["charm_respawn_ticks"])

	# Drifter
	c.drifter_speed_idle     = float(t["drifter_speed_idle"])
	c.drifter_speed_chase    = float(t["drifter_speed_chase"])
	c.drifter_speed_flee     = float(t["drifter_speed_flee"])
	c.drifter_detect_m       = float(t["drifter_detect_m"])
	c.drifter_steal_max_motes = int(t["drifter_steal_max_motes"])
	c.drifter_steal_radius   = float(t["drifter_steal_radius"])
	c.drifter_flee_ticks     = int(t["drifter_flee_ticks"])
	c.drifter_carried_min    = int(t["drifter_carried_min"])

	# Wind
	c.wind_cycle_ticks   = int(t["wind_cycle_ticks"])
	c.wind_warning_ticks = int(t["wind_warning_ticks"])
	c.wind_active_ticks  = int(t["wind_active_ticks"])
	c.wind_speed         = float(t["wind_speed"])

	# Score — canonical names map directly to contract keys
	c.score_per_mote         = int(sc["per_mote"])
	c.score_per_lantern      = int(sc["per_lantern"])
	c.score_per_stun         = int(sc["per_stun"])
	c.score_per_second_left  = int(sc["per_second_left"])
	c.score_per_flame_left   = int(sc["per_flame_left"])

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
